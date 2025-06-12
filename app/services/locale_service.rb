# ロケール関連の処理を集約するサービスクラス
# 主にコントローラーで利用される、ロケール決定とリダイレクト処理を担当
class LocaleService
  attr_reader :controller, :params, :request, :current_user

  # コントローラーのコンテキストを受け取るコンストラクタ
  def initialize(controller)
    @controller = controller
    @params = controller.params
    @request = controller.request
    @current_user = controller.current_user if controller.respond_to?(:current_user)
  end

  # ロケール設定のメイン処理
  def set_locale(locale = nil)
    I18n.locale = determine_effective_locale(locale)
  end

  # ユーザー設定からロケールを取得（LocaleHelperから移動）
  def extract_from_user(user)
    return nil unless user&.preferred_language.present?

    locale = user.preferred_language
    LocaleValidator.valid_locale?(locale) ? locale : nil
  end

  # HTTPヘッダーからロケールを取得（LocaleHelperから移動）
  def extract_from_header(accept_language_header)
    return nil unless accept_language_header.present?

    # http_accept_languageを使用してブラウザの言語設定を解析
    parser = HttpAcceptLanguage::Parser.new(accept_language_header)
    
    # 利用可能なロケールから最適なものを選択
    available_locales = LocaleConfiguration.available_locales.map(&:to_s)
    preferred_locale = parser.preferred_language_from(available_locales)
    
    LocaleValidator.valid_locale?(preferred_locale) ? preferred_locale : nil
  end

  # ユーザー設定に基づいてリダイレクトパスを決定（LocaleHelperから移動）
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
  # ステップ3で明示的ロケールが必須になったため、ロジックを簡素化
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
    extract_from_user(current_user) ||
      extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE']) ||
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
    LocaleHelper.current_path_with_locale(request, locale)
  end
end
