class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :conditional_auto_login

  rescue_from I18n::InvalidLocale, with: :handle_invalid_locale

  # URLヘルパーに自動的にロケールパラメータを追加
  def default_url_options
    # 常にロケールパラメータを付与する
    { locale: I18n.locale }
  end

  # ログイン後のリダイレクト先を決定
  def after_sign_in_path_for(resource)
    locale_service.determine_post_login_redirect_path(resource)
  end

  protected

  # ロケールを設定し、必要に応じてリダイレクトを実行
  def set_locale(locale = nil)
    locale_service.set_locale(locale)
  end

  private

  # ロケール例外時の共通処理
  def handle_invalid_locale(exception)
    Rails.logger.error("[Locale] Invalid locale error: #{exception.message} (params: #{params.inspect})")
    # ユーザーへの通知やリダイレクトは行わない
  end

  # ロケール処理を担当するサービスオブジェクト
  def locale_service
    @locale_service ||= LocaleService.new(self, current_user)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :preferred_language])
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
