# ロケール関連のユーティリティ処理を集約するヘルパーモジュール
# 低レベルなロケール操作（パス操作、文字列処理等）を担当
module LocaleHelper
  module_function

  # 現在のパスでロケールを変更したURLを生成（langパラメータ使用）
  def current_path_with_locale(request, locale)
    path = remove_locale_prefix(request.path)

    query_params = Rack::Utils.parse_query(request.query_string)
    query_params.delete('lang')
    query_params['lang'] = locale.to_s

    path + (query_params.any? ? "?#{query_params.to_query}" : "?lang=#{locale}")
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

  # ロケールリダイレクトをスキップすべきパスかどうかを判定
  def skip_locale_redirect?(path)
    # ヘルスチェック、ロケール切り替え、OmniAuth、APIエンドポイントなどはスキップ
    skip_paths = ['/up', '/locale', '/users/auth']
    skip_paths.any? { |skip_path| path.start_with?(skip_path) }
  end
end
