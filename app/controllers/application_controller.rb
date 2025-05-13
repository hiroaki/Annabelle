class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :conditional_auto_login

  # サインイン後のリダイレクト先を制御しています。
  # これは通常、デフォルトの root_path にリダイレクトしますが、
  # session[:just_signed_up] に値がセットされている場合は、プロフィール編集画面（edit）へ遷移させます。
  #
  # そのフローはセッションが新規登録ユーザーのものであることを想定しており、
  # ランダム生成された初期値のユーザー名などを編集してもらうための導線を意図しています。
  def after_sign_in_path_for(resource)
    if session.delete(:just_signed_up)
      edit_user_registration_path
    else
      super
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
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
