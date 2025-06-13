# ロケール関連のユーティリティ処理を集約するヘルパーモジュール
# 低レベルなロケール操作（パス操作、文字列処理等）を担当
module LocaleHelper
  module_function

  # 現在のパスでロケールを変更したURLを生成（パスベース戦略）
  def current_path_with_locale(request, locale)
    path = remove_locale_prefix(request.path)

    # パスベースロケール戦略に統一
    if locale.to_s == LocaleConfiguration.default_locale.to_s
      # デフォルトロケールの場合はプレフィックスなし
      path.empty? ? '/' : path
    else
      # 非デフォルトロケールの場合はプレフィックス付き
      if path.empty? || path == '/'
        "/#{locale}"
      else
        "/#{locale}#{path}"
      end
    end
  end

  # パスからロケールプレフィックスを削除
  def remove_locale_prefix(path)
    return '/' if path.blank? || path == '/'

    # ダブルスラッシュを修正
    path = path.gsub('//', '/')

    LocaleConfiguration.available_locales.each do |locale|
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
    # 明示的ロケール必須化により、全てのロケールでプレフィックスを追加
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

  # OAuth改善 - OAuth認証開始時のロケール処理
  def prepare_oauth_locale_params(params, session)
    oauth_params = {}

    # 1. 現在のロケールを優先（パスベース戦略に対応）
    candidate_locale = params[:locale] || I18n.locale.to_s
    current_effective_locale = LocaleValidator.valid_locale?(candidate_locale) ? candidate_locale : I18n.locale.to_s

    # 2. デフォルトロケール以外の場合のみパラメータを追加
    if current_effective_locale != I18n.default_locale.to_s && LocaleValidator.valid_locale?(current_effective_locale)
      oauth_params[:lang] = current_effective_locale
    # 3. 下位互換性のため、既存のlangパラメータも考慮
    elsif params[:lang].present? && LocaleValidator.valid_locale?(params[:lang])
      oauth_params[:lang] = params[:lang]
    end

    # OAuth認証開始前にセッションにロケールを保存（有効なロケールのみ）
    if LocaleValidator.valid_locale?(current_effective_locale)
      session[:oauth_locale] = current_effective_locale
      session[:oauth_locale_timestamp] = Time.current.to_i
    end

    oauth_params
  end
end
