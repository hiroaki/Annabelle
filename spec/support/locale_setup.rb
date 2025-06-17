RSpec.configure do |config|
  # テスト環境でのdefault_url_optionsを設定
  config.before(:each, type: :request) do
    # ApplicationControllerのdefault_url_optionsが正しく動作するよう、
    # I18n.localeを確実に設定
    I18n.locale = LocaleConfiguration.default_locale
  end

  config.before(:each, type: :system) do
    I18n.locale = LocaleConfiguration.default_locale
  end

  # 各テスト前にLocaleConfigurationの設定をI18nに適用
  config.before(:each) do
    # I18n設定をLocaleConfigurationと同期
    I18n.default_locale = LocaleConfiguration.default_locale
    allow(I18n).to receive(:available_locales).and_return(LocaleConfiguration.available_locales)
  end
end
