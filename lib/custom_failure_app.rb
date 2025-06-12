class CustomFailureApp < Devise::FailureApp
  def redirect_url
    # 明示的ロケール必須化対応：パスベースロケールでリダイレクト
    current_locale = determine_current_locale
    
    # ベースのリダイレクトURLを取得
    base_url = super
    
    # ロケールプレフィックスを追加
    add_locale_to_url(base_url, current_locale)
  end

  private

  def determine_current_locale
    # 1. 現在のI18n.locale
    return I18n.locale.to_s if valid_locale?(I18n.locale.to_s)
    
    # 2. リクエストパスからロケールを抽出
    if request.path.match(%r{^/([a-z]{2})(/|$)})
      path_locale = $1
      return path_locale if valid_locale?(path_locale)
    end
    
    # 3. langパラメータ（下位互換性）
    lang_param = request.params[:lang]
    return lang_param if valid_locale?(lang_param)
    
    # 4. デフォルトロケール
    LocaleConfiguration.default_locale.to_s
  end
  
  def add_locale_to_url(url, locale)
    # URLがフルURL（http://...）の場合、URIを使って適切にパスを処理
    if url.start_with?('http')
      uri = URI.parse(url)
      path = uri.path
      
      # パスがすでにロケールプレフィックスを持っている場合はそのまま返す
      return url if path.match(%r{^/[a-z]{2}/})
      
      # ロケールプレフィックスをパスに追加
      uri.path = "/#{locale}#{path}"
      return uri.to_s
    else
      # 相対パスの場合
      # パスがすでにロケールプレフィックスを持っている場合はそのまま返す
      return url if url.match(%r{^/[a-z]{2}/})
      
      # ロケールプレフィックスを追加
      "/#{locale}#{url}"
    end
  end

  def valid_locale?(locale)
    LocaleValidator.valid_locale?(locale)
  end
end