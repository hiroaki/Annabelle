class CustomFailureApp < Devise::FailureApp
  def redirect_url
    # LocaleServiceを利用してロケール判定とURL生成を一元化
    service = LocaleService.new(self)
    base_url = super
    locale = service.determine_effective_locale
    service.add_locale_to_url(base_url, locale)
  end
end