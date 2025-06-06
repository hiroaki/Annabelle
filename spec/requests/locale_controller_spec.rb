require 'rails_helper'

RSpec.describe LocaleController, type: :request do
  let(:user) { create(:user) }

  describe "GET /locale/:locale" do
    def set_cookie_header
      Array(response.headers["Set-Cookie"]).join("; ")
    end

    it "sets the locale cookie and redirects back" do
      get locale_path(locale: 'ja'), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(set_cookie_header).to include("locale=ja")
    end

    it "does not set locale cookie for unsupported locale" do
      get locale_path(locale: 'xx'), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      set_cookie_header = Array(response.headers["Set-Cookie"]).join("; ")
      expect(set_cookie_header).not_to include("locale=xx")
    end

    it "ignores invalid locale from cookie in locale resolution" do
      get root_path, headers: { 'Cookie' => 'locale=xx' }

      expect(I18n.locale).not_to eq(:xx)
      expect(I18n.available_locales.map(&:to_s)).to include(I18n.locale.to_s)
    end
  end
end
