# ロケール操作・パス生成・OAuth用パラメータなどを提供するヘルパー
module LocaleHelper
  # ロケールリダイレクトをスキップすべきパスか判定
  def skip_locale_redirect?(path)
    locales = I18n.available_locales.map(&:to_s)
    return false if path =~ %r{^/(#{locales.join('|')})(/|$)}
    true
  end

  # OAuth認証開始時のロケールパラメータ生成とセッション保存
  def prepare_oauth_locale_params(params, session)
    oauth_params = {}
    candidate = params[:locale] || I18n.locale.to_s
    effective = LocaleValidator.valid_locale?(candidate) ? candidate : I18n.locale.to_s
    if effective != I18n.default_locale.to_s && LocaleValidator.valid_locale?(effective)
      oauth_params[:lang] = effective
    elsif params[:lang].present? && LocaleValidator.valid_locale?(params[:lang])
      oauth_params[:lang] = params[:lang]
    end
    if LocaleValidator.valid_locale?(effective)
      session[:oauth_locale] = effective
      session[:oauth_locale_timestamp] = Time.current.to_i
    end
    oauth_params
  end

  # 指定パスシンボルのロケール付きURLを生成
  def localized_path_for(path_symbol, locale = nil, **options)
    locale ||= I18n.locale
    Rails.application.routes.url_helpers.send(path_symbol, **options.merge(locale: locale))
  end

  # リンクのCSSクラス（選択中ロケールで強調）
  def base_link_classes(locale, additional_classes = nil)
    classes = ["hover:text-slate-600"]
    classes << (I18n.locale == locale.to_sym ? 'font-bold' : '')
    classes << additional_classes if additional_classes.present?
    classes.compact.join(' ')
  end

  # パスのロケール部分を指定ロケールに付け替え
  def current_path_with_locale(path, locale)
    path_without = remove_locale_prefix(path)
    add_locale_prefix(path_without, locale)
  end

  private

  # パスからロケールプレフィックスを除去
  def remove_locale_prefix(path)
    return '/' if path.blank? || path == '/'
    validate_path!(path)
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

  # パスにロケールプレフィックスを付与
  def add_locale_prefix(path, locale)
    clean = remove_locale_prefix(path)
    clean = '/' if clean.blank?
    "/#{locale}#{clean == '/' ? '' : clean}"
  end

  # パスの形式バリデーション
  def validate_path!(path)
    return if path.blank?
    unless path.is_a?(String) && path.start_with?('/') &&
           !path.include?('//') &&
           !path.match?(/[[:cntrl:]\s]/) &&
           !path.split('/').include?('..')
      raise ArgumentError, "Invalid path format: must start with '/', not contain '//', '..', or control characters. Got: #{path.inspect}"
    end
  end
end
