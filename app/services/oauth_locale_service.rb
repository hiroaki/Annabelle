# OAuth認証時のロケール処理を担当するサービスクラス
class OAuthLocaleService < LocaleService
  OAUTH_LOCALE_SESSION_TTL = 600

  def initialize(controller, current_user = nil)
    super(controller, current_user)
    @controller = controller
  end

  # OAuth認証フロー中のロケールを決定するメイン処理
  def determine_oauth_locale
    result = extract_from_omniauth_params
    return result if result[:locale]

    result = extract_from_session
    return result if result[:locale]

    if current_user
      result = extract_from_user(current_user)
      return result if result[:locale]
    end

    result = extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
    return result if result[:locale]

    { locale: I18n.default_locale.to_s, source: LocaleService::SOURCE_DEFAULT }
  end

  # セッションからOAuth用に保存されたロケールを復元
  def restore_oauth_locale_from_session
    return nil unless @controller.session[:oauth_locale_timestamp]

    timestamp = @controller.session[:oauth_locale_timestamp].to_i
    if Time.current.to_i - timestamp < OAUTH_LOCALE_SESSION_TTL
      locale = @controller.session.delete(:oauth_locale)
      @controller.session.delete(:oauth_locale_timestamp)
      return { locale: locale } if LocaleValidator.valid_locale?(locale)
    else
      @controller.session.delete(:oauth_locale)
      @controller.session.delete(:oauth_locale_timestamp)
    end

    nil
  end

  private

  # OAuthパラメータからロケールを抽出
  def extract_from_omniauth_params
    omniauth_params = request.env["omniauth.params"] || {}
    oauth_locale = omniauth_params["lang"] || omniauth_params["locale"]

    if oauth_locale.present? && LocaleValidator.valid_locale?(oauth_locale)
      { locale: oauth_locale, source: LocaleService::SOURCE_OMNIAUTH_PARAMS }
    else
      { locale: nil, source: nil }
    end
  end

  # セッション情報からロケールを抽出
  def extract_from_session
    session_data = restore_oauth_locale_from_session
    return { locale: nil, source: nil } unless session_data

    locale = session_data.is_a?(Hash) ? session_data[:locale] : session_data
    if locale
      { locale: locale, source: LocaleService::SOURCE_SESSION }
    else
      { locale: nil, source: nil }
    end
  end
end
