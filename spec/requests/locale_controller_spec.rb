require 'rails_helper'

RSpec.describe LocaleController, type: :request do
  let(:user) { create(:user) }

  describe "GET /locale/:locale" do
    context "from root path" do
      it "redirects to root with lang parameter for Japanese" do
        get locale_path(locale: 'ja')

        expect(response).to redirect_to("/?lang=ja")
      end

      it "redirects to root with lang parameter for English" do
        get locale_path(locale: 'en')

        expect(response).to redirect_to("/?lang=en")
      end
    end

    context "from other paths" do
      it "preserves the current path and adds lang parameter" do
        # /messages にいるときに日本語に切り替える場合
        get locale_path(locale: 'ja'), env: { 'HTTP_REFERER' => 'http://www.example.com/messages' }

        expect(response).to redirect_to("/messages?lang=ja")
      end

      it "handles paths with existing query parameters" do
        # クエリパラメータがある場合
        get locale_path(locale: 'en'), env: { 'HTTP_REFERER' => 'http://www.example.com/users?page=2' }

        expect(response).to redirect_to("/users?lang=en&page=2")
      end
    end

    context "with unsupported locale" do
      it "redirects with alert for unsupported locale" do
        get locale_path(locale: 'xx')

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Unsupported locale")
      end
    end
  end
end
