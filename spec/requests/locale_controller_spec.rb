require 'rails_helper'

RSpec.describe LocaleController, type: :request do
  let(:user) { create(:user) }

  describe "GET /locale/:locale" do
    context "from root path" do
      it "redirects to root with Japanese locale prefix" do
        get locale_path(locale: 'ja')

        expect(response).to redirect_to("/ja")
      end

      it "redirects to root with prefix for English (default locale)" do
        get locale_path(locale: 'en')

        expect(response).to redirect_to("/en")
      end
    end

    context "from other paths" do
      it "preserves the current path with Japanese locale prefix" do
        # /messages にいるときに日本語に切り替える場合
        get locale_path(locale: 'ja'), env: { 'HTTP_REFERER' => 'http://www.example.com/messages' }

        expect(response).to redirect_to("/ja/messages")
      end

      it "handles paths with English (default) locale" do
        # すべてのロケールはプレフィックスあり
        get locale_path(locale: 'en'), env: { 'HTTP_REFERER' => 'http://www.example.com/ja/users' }

        expect(response).to redirect_to("/en/users")
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
