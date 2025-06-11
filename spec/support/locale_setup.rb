RSpec.configure do |config|
  # テスト環境でのdefault_url_optionsを設定
  config.before(:each, type: :request) do
    # ApplicationControllerのdefault_url_optionsが正しく動作するよう、
    # I18n.localeを確実に設定
    I18n.locale = :en
  end

  config.before(:each, type: :system) do
    I18n.locale = :en
  end
end
