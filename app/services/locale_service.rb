# ロケール関連の処理を集約するサービスクラス
# ロケール決定、言語切替、リダイレクト処理を担当
class LocaleService
  SOURCE_USER_PREFERENCE = :user_preference
  SOURCE_BROWSER_HEADER  = :browser_header
  SOURCE_OMNIAUTH_PARAMS = :omniauth_params
  SOURCE_SESSION         = :session
  SOURCE_DEFAULT         = :default

  attr_reader :controller, :params, :request, :current_user

  def initialize(controller, current_user = nil)
    @controller = controller
    @params = controller.params
    @request = controller.request
    @current_user = current_user
  end

  # ロケール設定のメイン処理
  def set_locale(locale = nil)
    I18n.locale = determine_effective_locale(locale)
  end

  # ユーザー設定からロケールを取得
  # @param user [User, nil] ユーザーオブジェクト（nilの場合は空の結果を返す）
  def extract_from_user(user)
    return { locale: nil, source: nil } unless user&.preferred_language.present?

    locale = user&.preferred_language
    if LocaleValidator.valid_locale?(locale)
      { locale: locale, source: SOURCE_USER_PREFERENCE }
    else
      { locale: nil, source: nil }
    end
  end

  # HTTPヘッダーからロケールを取得
  def extract_from_header(accept_language_header)
    return { locale: nil, source: nil } unless accept_language_header.present?

    # http_accept_languageを使用してブラウザの言語設定を解析
    parser = HttpAcceptLanguage::Parser.new(accept_language_header)
    
    # 利用可能なロケールから最適なものを選択
    available_locales = LocaleConfiguration.available_locales.map(&:to_s)
    preferred_locale = parser.preferred_language_from(available_locales)
    
    if LocaleValidator.valid_locale?(preferred_locale)
      { locale: preferred_locale, source: SOURCE_BROWSER_HEADER }
    else
      { locale: nil, source: nil }
    end
  end

  # ユーザー設定に基づいてリダイレクトパスを決定
  def redirect_path_for_user(resource)
    # フォールバックロケールを使用してリダイレクト先を決定
    fallback_locale = determine_fallback_locale

    if fallback_locale != LocaleConfiguration.default_locale.to_s
      # デフォルト以外の言語の場合、その言語のrootパスにリダイレクト
      "/#{fallback_locale}"
    else
      # デフォルト言語の場合はrootパス（ApplicationControllerで解決）
      :root_path
    end
  end

  # ロケール決定の優先順位を一元化
  # 明示的ロケールが必須になったため、ロジックを簡素化
  def determine_effective_locale(locale = nil)
    # 1. 明示的な引数（メソッド呼び出し時の指定）
    return locale.to_s if LocaleValidator.valid_locale?(locale)

    # 2. URLパスのlocale（明示的ロケール必須化により常に存在）
    url_locale = params[:locale]
    return url_locale.to_s if LocaleValidator.valid_locale?(url_locale)

    # 3. フォールバック（リダイレクト処理時やOAuth例外時のみ使用）
    determine_fallback_locale
  end

  # フォールバック用のロケール決定（リダイレクト時やOAuth例外時）
  def determine_fallback_locale
    # ユーザー設定 → ブラウザ設定 → デフォルト
    if current_user
      result = extract_from_user(current_user)
      return result[:locale] if result[:locale]
    end

    result = extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
    return result[:locale] if result[:locale]

    LocaleConfiguration.default_locale.to_s
  end

  # ログイン後のリダイレクト先を決定
  def determine_post_login_redirect_path(resource)
    stored_location = controller.stored_location_for(resource)

    if stored_location.present?
      # "/ja" のようなロケールのみのパスを適切なパスに変換
      if stored_location.match?(/^\/[a-z]{2}$/)
        redirect_path_with_user_locale(resource)
      else
        stored_location
      end
    else
      redirect_path_with_user_locale(resource)
    end
  end

  # ユーザーの言語設定に基づいてリダイレクトパスを決定
  def redirect_path_with_user_locale(resource)
    result = redirect_path_for_user(resource)
    result == :root_path ? controller.root_path : result
  end

  # 現在のパスでロケールを変更したURLを生成
  def current_path_with_locale(locale)
    LocaleHelper.current_path_with_locale(request.path, locale)
  end

  # 指定URLにロケールを付与したURLを返す
  # パス操作はヘルパーに委譲し、ロケール決定のみサービスで担当
  def add_locale_to_url(url, locale = nil)
    locale ||= determine_effective_locale
    return url if locale.nil? || locale.empty?

    if url.start_with?('http')
      uri = URI.parse(url)
      path = uri.path
      # 既にロケールが付与されていればそのまま返す
      return url if path.match(%r{^/[a-z]{2}/})
      uri.path = LocaleHelper.add_locale_prefix(LocaleHelper.remove_locale_prefix(path), locale)
      uri.to_s
    else
      # 相対パスの場合
      LocaleHelper.add_locale_prefix(LocaleHelper.remove_locale_prefix(url), locale)
    end
  end
end
