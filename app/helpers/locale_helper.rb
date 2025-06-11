# ロケール関連のユーティリティ処理を集約するヘルパーモジュール
# 低レベルなロケール操作（パス操作、文字列処理等）を担当
module LocaleHelper
  module_function

  # ユーザー設定からロケールを取得
  def extract_from_user(user)
    return nil unless user&.preferred_language.present?

    locale = user.preferred_language
    LocaleValidator.valid_locale?(locale) ? locale : nil
  end

  # HTTPヘッダーからロケールを取得
  def extract_from_header(accept_language_header)
    return nil unless accept_language_header.present?

    locale = accept_language_header.scan(/^[a-z]{2}/).first
    LocaleValidator.valid_locale?(locale) ? locale : nil
  end

  # 現在のパスでロケールを変更したURLを生成（langパラメータ使用）
  def current_path_with_locale(request, locale)
    path = remove_locale_prefix(request.path)

    query_params = Rack::Utils.parse_query(request.query_string)
    query_params.delete('lang')
    query_params['lang'] = locale.to_s

    path + (query_params.any? ? "?#{query_params.to_query}" : "?lang=#{locale}")
  end

  # ユーザー設定に基づいてリダイレクトパスを決定
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

  # パスからロケールプレフィックスを削除
  def remove_locale_prefix(path)
    return '/' if path.blank? || path == '/'

    # ダブルスラッシュを修正
    path = path.gsub('//', '/')

    I18n.available_locales.each do |locale|
      locale_str = locale.to_s
      if path.start_with?("/#{locale_str}/")
        return path.sub(%r{^/#{locale_str}}, '')
      elsif path == "/#{locale_str}"
        return '/'
      end
    end

    path
  end

  # パスにロケールプレフィックスを追加
  def add_locale_prefix(path, locale)
    return path if locale.to_s == I18n.default_locale.to_s

    clean_path = remove_locale_prefix(path)
    clean_path = '/' if clean_path.blank?

    "/#{locale}#{clean_path == '/' ? '' : clean_path}"
  end

  # 現在のパスにロケールを追加したパスを生成
  def localized_path(path, locale, query_string = nil)
    return nil if locale.to_s == I18n.default_locale.to_s

    if path == '/' || path.empty?
      localized_path = "/#{locale}/"
    else
      localized_path = "/#{locale}#{path}"
    end

    if query_string.present?
      localized_path += "?#{query_string}"
    end

    localized_path
  end

  # ロケールリダイレクトをスキップすべきパスかどうかを判定
  def skip_locale_redirect?(path)
    # ヘルスチェック、ロケール切り替え、OmniAuth、APIエンドポイントなどはスキップ
    skip_paths = ['/up', '/locale', '/users/auth']
    skip_paths.any? { |skip_path| path.start_with?(skip_path) }
  end

  # URLがデフォルトロケールを示しているかどうかを判定
  def url_indicates_default_locale?(params, path)
    return params[:lang] == I18n.default_locale.to_s if params[:lang].present?
    path != '/'
  end
end
