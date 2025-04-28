class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!, only: [:unlink_oauth]

  # OAuth 認証を解除するアクション
  def unlink_oauth
    provider_name = OmniAuth::Utils.camelize(current_user.provider)
    current_user.update(provider: nil, uid: nil)
    redirect_to edit_user_registration_path, notice: "#{provider_name}認証を無効化しました。"
  end
end
