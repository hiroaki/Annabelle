# OAuth認証時のロケール処理を担当するサービスクラス
class OAuthLocaleService
  OAUTH_LOCALE_SESSION_TTL = 600

  attr_reader :controller, :current_user, :request

  def initialize(controller, current_user = nil)
    @controller = controller
    @current_user = current_user
    @request = controller.request
  end

  # OAuth認証フロー中のロケールを決定するメイン処理
  def determine_oauth_locale
    extract_from_omniauth_params ||
      extract_from_session ||
      extract_from_user ||
      extract_from_header ||
      I18n.default_locale.to_s
  end

  private

  def valid_locale_or_nil(locale)
    locale if locale.present? && LocaleValidator.valid_locale?(locale)
  end

  # OAuthパラメータからロケールを抽出
  def extract_from_omniauth_params
    omniauth_params = request.env["omniauth.params"] || {}
    oauth_locale = omniauth_params["lang"] || omniauth_params["locale"]
    valid_locale_or_nil(oauth_locale)
  end

  # セッション情報からロケールを抽出
  def extract_from_session
    locale = restore_oauth_locale_from_session
    valid_locale_or_nil(locale)
  end

  # ユーザー設定からロケールを取得
  def extract_from_user
    valid_locale_or_nil(current_user&.preferred_language)
  end

  # HTTPヘッダーからロケールを取得
  def extract_from_header
    accept_language_header = request.env['HTTP_ACCEPT_LANGUAGE']
    return nil unless accept_language_header.present?
    parser = HttpAcceptLanguage::Parser.new(accept_language_header)
    available_locales = LocaleConfiguration.available_locales.map(&:to_s)
    preferred_locale = parser.preferred_language_from(available_locales)
    valid_locale_or_nil(preferred_locale)
  end

  # セッションからOAuth用に保存されたロケールを復元
  def restore_oauth_locale_from_session
    return nil unless controller.session[:oauth_locale_timestamp]

    timestamp = controller.session[:oauth_locale_timestamp].to_i
    within_ttl = Time.current.to_i - timestamp < OAUTH_LOCALE_SESSION_TTL
    locale = within_ttl ? controller.session[:oauth_locale] : nil

    controller.session.delete(:oauth_locale)
    controller.session.delete(:oauth_locale_timestamp)

    locale
  end
end
