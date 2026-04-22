class ApplicationController < ActionController::Base
  class << self
    attr_accessor :legacy_basic_auth_warning_emitted
  end

  before_action :http_basic_authenticate
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :conditional_auto_login

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

  def set_locale
    I18n.locale = LocaleUtils.determine_locale(params, request, current_user)
  end

  private

  # ENABLED_BASIC_AUTH が設定されている場合は新方式のみを利用し、
  # 未設定時のみ互換性のため BASIC_AUTH_USER/BASIC_AUTH_PASSWORD を利用します。
  def http_basic_authenticate
    if ENV.key?('ENABLED_BASIC_AUTH')
      authenticate_with_basic_auth
    else
      authenticate_with_basic_auth_legacy
    end
  end

  def basic_auth_enabled?
    # Note: This guard is important for future cleanup.
    # When legacy support is removed, http_basic_authenticate will always call this method,
    # so this check will become the main gate for enabling Basic Auth.
    return false unless ENV.key?('ENABLED_BASIC_AUTH')

    ActiveModel::Type::Boolean.new.cast(ENV['ENABLED_BASIC_AUTH'])
  end

  def configured_basic_auth_pairs
    parse_basic_auth_pairs(ENV['BASIC_AUTH_PAIRS'])
  end

  def parse_basic_auth_pairs(raw_pairs)
    raw_pairs.to_s.split(',').filter_map do |pair|
      user, pswd = pair.split(':', 2)
      next if user.blank? || pswd.blank?

      [user, pswd]
    end
  end

  def authenticate_with_basic_auth
    return unless basic_auth_enabled?

    pairs = configured_basic_auth_pairs
    authenticate_or_request_with_http_basic do |username, password|
      pairs.any? do |user, pswd|
        secure_eq(username, user) & secure_eq(password, pswd)
      end
    end
  end

  def secure_eq(string_a, string_b)
    Rack::Utils.secure_compare(
      Digest::SHA256.hexdigest(string_a.to_s),
      Digest::SHA256.hexdigest(string_b.to_s)
    )
  end

  #---

  def authenticate_with_basic_auth_legacy
    pairs = configured_basic_auth_pairs_legacy
    return if pairs.empty?

    authenticate_or_request_with_http_basic do |username, password|
      pairs.any? do |user, pswd|
        secure_eq(username, user) & secure_eq(password, pswd)
      end
    end
  end

  def basic_auth_enabled_legacy?
    basic_auth_user_legacy && basic_auth_password_legacy
  end

  def configured_basic_auth_pairs_legacy
    return [] unless basic_auth_enabled_legacy?

    warn_legacy_basic_auth_env_once
    [[basic_auth_user_legacy, basic_auth_password_legacy]]
  end

  def warn_legacy_basic_auth_env_once
    return if ApplicationController.legacy_basic_auth_warning_emitted

    Rails.logger.warn('[BasicAuth] BASIC_AUTH_USER/BASIC_AUTH_PASSWORD are deprecated. Use BASIC_AUTH_PAIRS instead.')
    ApplicationController.legacy_basic_auth_warning_emitted = true
  end

  def basic_auth_user_legacy
    ENV['BASIC_AUTH_USER'].presence
  end

  def basic_auth_password_legacy
    ENV['BASIC_AUTH_PASSWORD'].presence
  end

  #---

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
      raise 'conditional_auto_login failed'
    end
    sign_in(:user, user)
  end
end
