class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!, only: [:unlink_oauth]

  # OAuth 認証を解除するアクション
  def unlink_oauth
    provider = params[:provider]
    auth = current_user.authorizations.find_by(provider: provider)

    if auth
      provider_name = OmniAuth::Utils.camelize(provider)
      if auth.destroy
        redirect_to edit_user_registration_path, notice: "#{provider_name} 認証を解除しました。"
      else
        redirect_to edit_user_registration_path, alert: "#{provider_name} 認証の解除に失敗しました。"
      end
    else
      redirect_to edit_user_registration_path, alert: "指定された連携が見つかりません。"
    end
  end
end
