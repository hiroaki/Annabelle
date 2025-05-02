class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :conditional_auto_login

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  # My experimental feature
  def conditional_auto_login
    return unless Rails.configuration.x.auto_login.enabled
    return if user_signed_in?

    email = Rails.configuration.x.auto_login.email.presence
    user = email ? User.find_by!(email: email) : User.admin_user
    if !user.present? || !user.active_for_authentication?
      # 実行時までここのエラーに気が付けないですが、
      # このケースはいわゆる「一人で使うためのモード」の中であるため許容します。
      raise "conditional_auto_login failed"
    end

    # ログイン不可な user をセットしてしまうと無限ループに陥るので注意。
    sign_in(:user, user)
  end
end
