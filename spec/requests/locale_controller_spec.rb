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
      it "preserves the current path with Japanese locale prefix when redirect_to is provided" do
        # redirect_toパラメータで/messagesに移動する場合
        get locale_path(locale: 'ja', redirect_to: '/messages')

        expect(response).to redirect_to("/ja/messages")
      end

      it "handles paths with English (default) locale when redirect_to is provided" do
        # redirect_toパラメータで/usersに移動する場合
        get locale_path(locale: 'en', redirect_to: '/users')

        expect(response).to redirect_to("/en/users")
      end
    end

    context "with unsupported locale" do
      it "redirects with alert for unsupported locale" do
        get locale_path(locale: 'xx')

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Unsupported locale")
      end

      it "redirects with alert for unsupported locale (user-friendly message)" do
        get locale_path(locale: 'xx')

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t('errors.locale.unsupported_locale'))
      end
    end
  end
end
