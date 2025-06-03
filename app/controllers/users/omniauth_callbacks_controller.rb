class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :github

  def github
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      if current_user.linked_with?(auth.provider) && current_user.provider_uid(auth.provider) != auth.uid
        flash[:alert] = I18n.t("devise.omniauth_callbacks.provider.already_linked", provider: OmniAuth::Utils.camelize(auth.provider))
        redirect_to edit_user_registration_path and return
      else
        current_user.link_with(auth.provider, auth.uid)
        flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider))
        redirect_to edit_user_registration_path
      end
    else
      @user = User.from_omniauth(auth)

      if @user&.persisted?
        if @user.saved_change_to_id?
          session[:just_signed_up] = true
        end

        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, provider: OmniAuth::Utils.camelize(auth.provider)) if is_navigational_format?
      else
        session["devise.github_data"] = auth.except(:extra)
        redirect_to new_user_registration_path, alert: I18n.t("devise.omniauth_callbacks.failure", provider: OmniAuth::Utils.camelize(auth.provider))
      end
    end
  end

  def failure
    provider = request.env["omniauth.error.strategy"]&.name&.to_s&.humanize || I18n.t("devise.omniauth_callbacks.unknown_provider")
    redirect_to new_user_session_path, alert: I18n.t("devise.omniauth_callbacks.failure", provider: provider)
  end
end
