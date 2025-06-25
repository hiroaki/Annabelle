class CustomFailureApp < Devise::FailureApp
  def redirect_url
    # LocaleServiceのクラスメソッドでロケール判定とURL生成を行う
    base_url = super
    locale = LocaleService.determine_locale(params, request, nil)
    # add_locale_to_url相当の処理をここで直接記述（必要ならヘルパー化）
    if locale && !base_url.include?("/#{locale}")
      uri = URI.parse(base_url)
      uri.path = "/#{locale}" + uri.path.sub(/^\/[a-z]{2}/, '')
      uri.to_s
    else
      base_url
    end
  end
end