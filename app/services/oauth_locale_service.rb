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
    locale = extract_from_omniauth_params ||
             extract_from_session ||
             (current_user && extract_from_user(current_user)) ||
             extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE']) ||
             I18n.default_locale.to_s
    locale
  end

  # セッションからOAuth用に保存されたロケールを復元
  def restore_oauth_locale_from_session
    return nil unless controller.session[:oauth_locale_timestamp]

    timestamp = controller.session[:oauth_locale_timestamp].to_i
    if Time.current.to_i - timestamp < OAUTH_LOCALE_SESSION_TTL
      locale = controller.session.delete(:oauth_locale)
      controller.session.delete(:oauth_locale_timestamp)
      return { locale: locale } if LocaleValidator.valid_locale?(locale)
    else
      controller.session.delete(:oauth_locale)
      controller.session.delete(:oauth_locale_timestamp)
    end

    nil
  end

  private

  # OAuthパラメータからロケールを抽出
  def extract_from_omniauth_params
    omniauth_params = request.env["omniauth.params"] || {}
    oauth_locale = omniauth_params["lang"] || omniauth_params["locale"]
    oauth_locale if oauth_locale.present? && LocaleValidator.valid_locale?(oauth_locale)
  end

  # セッション情報からロケールを抽出
  def extract_from_session
    session_data = restore_oauth_locale_from_session
    locale = session_data.is_a?(Hash) ? session_data[:locale] : session_data
    locale if locale && LocaleValidator.valid_locale?(locale)
  end

  # ユーザー設定からロケールを取得
  def extract_from_user(user)
    locale = user&.preferred_language
    locale if locale.present? && LocaleService.valid_locale?(locale)
  end

  # HTTPヘッダーからロケールを取得
  def extract_from_header(accept_language_header)
    return nil unless accept_language_header.present?
    parser = HttpAcceptLanguage::Parser.new(accept_language_header)
    available_locales = LocaleConfiguration.available_locales.map(&:to_s)
    preferred_locale = parser.preferred_language_from(available_locales)
    preferred_locale if LocaleService.valid_locale?(preferred_locale)
  end
end
