# ロケール関連のヘルパーモジュール（統合版）
# パス・URL操作、ロケール判定、OAuth処理などを統一的に提供
module LocaleHelper
  include LocalePathUtils
  
  # LocalePathUtilsのメソッドをモジュールメソッドとして公開
  module_function :current_path_with_locale, :remove_locale_prefix, :add_locale_prefix

  # ロケールリダイレクトをスキップすべきパスかどうかを判定
  def skip_locale_redirect?(path)
    # ヘルスチェック、ロケール切り替え、OmniAuth、APIエンドポイントなどはスキップ
    skip_paths = ['/up', '/locale', '/users/auth']
    skip_paths.any? { |skip_path| path.start_with?(skip_path) }
  end
  module_function :skip_locale_redirect?

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
  module_function :prepare_oauth_locale_params

  # ロケール付きパスの生成（旧LocaleUrlHelperから統合）
  def localized_path_for(path_symbol, locale = nil, **options)
    locale ||= I18n.locale

    # すべてのロケールでプレフィックスを付与
    Rails.application.routes.url_helpers.send(path_symbol, **options.merge(locale: locale))
  end
  module_function :localized_path_for

  # リンクのベースCSSクラスを生成（旧LocaleUrlHelperから統合）
  def base_link_classes(locale, additional_classes = nil)
    classes = ["hover:text-slate-600"]
    classes << (I18n.locale == locale.to_sym ? 'font-bold' : '')
    classes << additional_classes if additional_classes.present?
    classes.compact.join(' ')
  end
  module_function :base_link_classes
end
