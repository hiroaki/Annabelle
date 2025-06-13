# ロケール関連のURL生成を統一するヘルパーモジュール
# URL戦略の統一化とヘルパーメソッドの整備
module LocaleUrlHelper
  module_function

  # 現在のパスベースURL生成メソッド（ステップ4: 統一戦略）
  # 例: current_path_with_locale_path(request, :ja) => "/ja/messages"
  def current_path_with_locale_path(request, locale)
    path = LocaleHelper.remove_locale_prefix(request.path)
    LocaleHelper.add_locale_prefix(path, locale)
  end

  # パスベースURL戦略に統一
  # 後方互換性のため、パスベースURL生成にリダイレクト
  def current_path_with_locale_query(request, locale)
    current_path_with_locale_path(request, locale)
  end

  # 統一されたURL生成メソッド（ステップ4: パスベース戦略に統一）
  def current_path_with_locale_unified(request, locale)
    current_path_with_locale_path(request, locale)
  end

  # パスベースロケールを使用するかどうかの判定
  def use_path_based_locale?
    # パスベースロケール戦略有効時の判定（環境変数やconfigで制御）
    return false unless Rails.application.config.respond_to?(:x)
    return false unless Rails.application.config.x.respond_to?(:use_path_based_locale)

    # 明示的にtrueの場合のみtrue、それ以外はfalse
    Rails.application.config.x.use_path_based_locale == true
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

    if use_path_based_locale?
      # パスベース方式: /ja/users/edit
      if locale.to_s == LocaleConfiguration.default_locale.to_s
        Rails.application.routes.url_helpers.send(path_symbol, **options)
      else
        Rails.application.routes.url_helpers.send(path_symbol, **options.merge(locale: locale))
      end
    else
      # クエリパラメータ方式: /users/edit?lang=ja
      base_path = Rails.application.routes.url_helpers.send(path_symbol, **options)
      if locale.to_s != LocaleConfiguration.default_locale.to_s
        separator = base_path.include?('?') ? '&' : '?'
        "#{base_path}#{separator}lang=#{locale}"
      else
        base_path
      end
    end
  end

  # リンクのベースCSSクラスを生成
  def base_link_classes(locale, additional_classes = nil)
    classes = ["hover:text-slate-600"]
    classes << (I18n.locale == locale.to_sym ? 'font-bold' : '')
    classes << additional_classes if additional_classes.present?
    classes.compact.join(' ')
  end

end
