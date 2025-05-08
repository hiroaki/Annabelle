class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!, only: [:unlink_oauth]

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
end
