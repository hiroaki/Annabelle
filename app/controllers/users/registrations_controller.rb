# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include DeviseHelper

  before_action :authenticate_user!, only: [:unlink_oauth]
  before_action :configure_account_update_params, only: [:update]

  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # OAuth 認証を解除するアクション
  def unlink_oauth
    provider = params[:provider]
    auth = current_user.authorizations.find_by(provider: provider)

    if auth
      provider_name = OmniAuth::Utils.camelize(provider)
      if auth.destroy
        redirect_to edit_user_registration_path, notice: I18n.t("devise.registrations.unlink_oauth.success", provider_name: provider_name)
      else
        redirect_to edit_user_registration_path, alert: I18n.t("devise.registrations.unlink_oauth.failure", provider_name: provider_name)
      end
    else
      redirect_to edit_user_registration_path, alert: I18n.t("devise.registrations.unlink_oauth.not_found")
    end
  end

  # (override)
  def after_update_path_for(resource)
    devise_edit_registration_path_for(resource)
  end

  # GET /resource/sign_up
  def new
    @language_switcher_path = new_user_registration_path
    super
  end

  # POST /resource
  def create
    @language_switcher_path = new_user_registration_path
    super
  end

  # GET /resource/edit
  def edit
    @language_switcher_path = edit_user_registration_path
    super
  end

  # PUT /resource
  def update
    @language_switcher_path = edit_user_registration_path
    super
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:otp_required_for_login])
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # (override)
  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    new_session_path(resource_name)
  end

  # (override)
  # デフォルトの root_path はログインが必須なため、ログイン画面へリダイレクトします。
  # 結果的に同じ画面へすすむのですが、リダイレクトが挟まると flash が消えてしまうため、
  # ここで直接ログイン画面を指定するようにしています。
  def after_sign_out_path_for(resource_or_scope)
    new_session_path(resource_or_scope)
  end

  private

  def devise_edit_registration_path_for(resource)
    devise_path_for(:edit, resource)
  end
end
