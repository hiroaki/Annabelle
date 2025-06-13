# ロケール関連のURL生成を統一するヘルパーモジュール
# URL戦略の統一化とヘルパーメソッドの整備
module LocaleUrlHelper
  module_function

  # ロケールプレフィックス付きのURLを生成
  # 例: current_path_with_locale_path(request, :ja) => "/ja/messages"
  def current_path_with_locale_path(request, locale)
    path = LocaleHelper.remove_locale_prefix(request.path)
    LocaleHelper.add_locale_prefix(path, locale)
  end

  # 標準のURL生成メソッド
  def current_path_with_locale_unified(request, locale)
    current_path_with_locale_path(request, locale)
  end

  # 言語切り替えリンク生成（ビューで使用）
  def locale_switch_link_to(text, locale, request, options = {})
    url = current_path_with_locale_unified(request, locale)
    css_classes = base_link_classes(locale, options[:class])

    # このメソッドはビューから呼ばれることを前提とし、単純にURLとクラスを返す
    {
      text: text,
      url: url,
      class: css_classes,
      options: options.except(:class)
    }
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
