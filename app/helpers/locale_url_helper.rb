# ロケール関連のURL生成を統一するヘルパーモジュール
# URL戦略の統一化とヘルパーメソッドの整備
module LocaleUrlHelper
  module_function

  # ロケールプレフィックス付きのURLを生成
  # 例: current_path_with_locale_path('/messages', :ja) => "/ja/messages"
  def current_path_with_locale_path(path, locale)
    path_without_locale = LocaleHelper.remove_locale_prefix(path)
    LocaleHelper.add_locale_prefix(path_without_locale, locale)
  end



  # ロケール付きパスの生成（コントローラーで使用）
  def localized_path_for(path_symbol, locale = nil, **options)
    locale ||= I18n.locale

    # すべてのロケールでプレフィックスを付与
    Rails.application.routes.url_helpers.send(path_symbol, **options.merge(locale: locale))
  end

  # リンクのベースCSSクラスを生成
  def base_link_classes(locale, additional_classes = nil)
    classes = ["hover:text-slate-600"]
    classes << (I18n.locale == locale.to_sym ? 'font-bold' : '')
    classes << additional_classes if additional_classes.present?
    classes.compact.join(' ')
  end
end
