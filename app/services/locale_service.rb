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

    locale = accept_language_header.scan(/^[a-z]{2}/).first
    LocaleValidator.valid_locale?(locale) ? locale : nil
  end

  # ユーザー設定に基づいてリダイレクトパスを決定（LocaleHelperから移動）
  def redirect_path_for_user(resource)
    user_locale = extract_from_user(resource)

    if user_locale && user_locale != I18n.default_locale.to_s
      # ユーザーの設定言語がデフォルト以外の場合、その言語のrootパスにリダイレクト
      "/#{user_locale}"
    else
      # デフォルト言語またはユーザー設定がない場合はrootパス（ApplicationControllerで解決）
      :root_path
    end
  end

  # ロケール決定の優先順位を一元化
  def determine_effective_locale(locale = nil)
    # 1. 明示的な引数
    return locale.to_s if LocaleValidator.valid_locale?(locale)

    # 2. langクエリパラメータ（一時的な言語切り替え）
    lang_param = params[:lang]
    return lang_param.to_s if LocaleValidator.valid_locale?(lang_param)

    # 3. URLパスのlocale（RESTfulなURL）
    # WARN: localeが省略されたパスの場合はここで決定せずユーザー設定の判定へ。
    url_locale = params[:locale]
    return url_locale.to_s if LocaleValidator.valid_locale?(url_locale)

    # 4. ユーザー設定言語
    user_locale = extract_from_user(current_user)
    return user_locale if user_locale

    # 5. ブラウザ設定言語
    header_locale = extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
    return header_locale if header_locale

    # 6. デフォルト言語
    I18n.default_locale.to_s
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
