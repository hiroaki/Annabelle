class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :conditional_auto_login
  before_action :set_app_response_header

  rescue_from I18n::InvalidLocale, with: :handle_invalid_locale

  # URLヘルパーに自動的にロケールパラメータを追加
  def default_url_options
    { locale: I18n.locale }
  end

  # ログイン後のリダイレクト先を決定
  def after_sign_in_path_for(resource)
    stored_location = stored_location_for(resource)
    if stored_location.present?
      uri = URI.parse(stored_location)
      # 既存のロケール部分を現在のI18n.localeで置換
      uri.path = uri.path.sub(/^\/[a-z]{2}/, "/#{I18n.locale}")
      uri.to_s
    else
      root_path(locale: I18n.locale)
    end
  end

  protected

  # ロケールを設定（1リクエスト1回のみ）
  def set_locale
    I18n.locale = LocaleUtils.determine_locale(params, request, current_user)
  end

  private

  # Add custom header to distinguish Rails app responses from proxy responses
  def set_app_response_header
    response.headers['X-App-Response'] = 'true'
  end

  def handle_invalid_locale(exception)
    Rails.logger.error("[Locale] Invalid locale error: #{exception.message} (params: #{params.inspect})")
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :preferred_language])
  end

  def conditional_auto_login
    return unless Rails.configuration.x.auto_login.enabled
    return if user_signed_in?
    email = Rails.configuration.x.auto_login.email.presence
    user = email ? User.find_by!(email: email) : User.admin_user
    if !user.present? || !user.active_for_authentication?
      raise "conditional_auto_login failed"
    end
    sign_in(:user, user)
  end
end
