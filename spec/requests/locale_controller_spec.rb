require 'rails_helper'

RSpec.describe LocaleController, type: :request, oauth_github_required: true do
  let(:user) { create(:user) }

  describe "GET /locale/:locale" do
    context "when accessed from the root path" do
      it "redirects to /ja when locale is 'ja'" do
        get locale_path(locale: 'ja')

        expect(response).to redirect_to("/ja")
      end

      it "redirects to /en when locale is 'en' (default)" do
        get locale_path(locale: 'en')

        expect(response).to redirect_to("/en")
      end
    end

    context "when accessed from another path with redirect_to param" do
      it "redirects to /ja/messages when redirect_to is provided with locale 'ja'" do
        get locale_path(locale: 'ja', redirect_to: '/messages')

        expect(response).to redirect_to("/ja/messages")
      end

      it "redirects to /en/users when redirect_to is provided with locale 'en'" do
        get locale_path(locale: 'en', redirect_to: '/users')

        expect(response).to redirect_to("/en/users")
      end
    end

    context "when redirect_to param contains invalid paths" do
      it "redirects to /ja when redirect_to contains double slashes (// attack)" do
        expect(Rails.logger).to receive(:warn).with(/Invalid redirect path/)

        get locale_path(locale: 'ja', redirect_to: '//evil.example.com')

        expect(response).to redirect_to("/ja")
        expect(flash[:alert]).to eq(I18n.t('errors.locale.invalid_redirect_path'))
      end

      it "redirects to /en when redirect_to contains path traversal (../ attack)" do
        expect(Rails.logger).to receive(:warn).with(/Invalid redirect path/)

        get locale_path(locale: 'en', redirect_to: '/../../etc/passwd')

        expect(response).to redirect_to("/en")
        expect(flash[:alert]).to eq(I18n.t('errors.locale.invalid_redirect_path'))
      end

      it "redirects to /ja when redirect_to contains control characters" do
        expect(Rails.logger).to receive(:warn).with(/Invalid redirect path/)

        get locale_path(locale: 'ja', redirect_to: "/path\nwith\tcontrol")

        expect(response).to redirect_to("/ja")
        expect(flash[:alert]).to eq(I18n.t('errors.locale.invalid_redirect_path'))
      end

      it "redirects to /en when redirect_to is not a string starting with /" do
        expect(Rails.logger).to receive(:warn).with(/Invalid redirect path/)

        get locale_path(locale: 'en', redirect_to: 'invalid-path')

        expect(response).to redirect_to("/en")
        expect(flash[:alert]).to eq(I18n.t('errors.locale.invalid_redirect_path'))
      end

      it "handles exceptions gracefully when current_path_with_locale raises LocalePathValidationError" do
        allow_any_instance_of(LocaleController).to receive(:current_path_with_locale).and_raise(LocaleHelper::LocalePathValidationError, "Test error")
        expect(Rails.logger).to receive(:warn).with("Invalid redirect path: Test error")

        get locale_path(locale: 'ja', redirect_to: '/valid/path')

        expect(response).to redirect_to("/ja")
        expect(flash[:alert]).to eq(I18n.t('errors.locale.invalid_redirect_path'))
      end
    end

    context "when locale is unsupported" do
      it "redirects to root with a default alert message" do
        get locale_path(locale: 'xx')

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Unsupported locale")
      end

      it "redirects to root with an i18n alert message" do
        get locale_path(locale: 'xx')

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t('errors.locale.unsupported_locale'))
      end
    end
  end

  # Shared examples for locale auto-detection and redirect
  shared_examples "common locale redirect tests" do |headers, expected_locale|
    it "redirects / to the expected locale root" do
      get "/", headers: headers

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/#{expected_locale}")
    end

    it "redirects / with query params to the expected locale root, preserving params" do
      get "/?test=value", headers: headers

      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to include("/#{expected_locale}")
      expect(response.location).to include("test=value")
    end

    it "redirects to the expected locale root after visiting /locale/ja and then /" do
      get "/locale/ja"
      get "/", headers: headers

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/#{expected_locale}")
    end
  end

  describe "GET /" do
    context "when Accept-Language header is not present" do
      include_examples "common locale redirect tests", {}, "en"
    end

    context "when Accept-Language header prefers Japanese" do
      include_examples "common locale redirect tests", { "Accept-Language" => "ja,en;q=0.9" }, "ja"
    end
  end

  describe "explicit locale required routing" do
    context "when accessing a valid locale path" do
      it "returns 200 or 302 for /ja" do
        get "/ja"

        expect([200, 302]).to include(response.status)
      end

      it "returns 200 or 302 for /en" do
        get "/en"

        expect([200, 302]).to include(response.status)
      end
    end

    context "when accessing an invalid locale path" do
      it "returns 404 for /invalid" do
        get "/invalid"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "OAuth exception routing" do
    context "when accessing OAuth callback URLs" do
      it "does not return 404 for /users/auth/github/callback" do
        get "/users/auth/github/callback"

        expect(response).not_to have_http_status(:not_found)
      end

      it "does not return 404 for POST /users/auth/github" do
        post "/users/auth/github"

        expect(response).not_to have_http_status(:not_found)
      end
    end

    context "when accessing OAuth failure path" do
      it "returns a redirect for /users/auth/failure and not 404" do
        get "/users/auth/failure"

        expect(response).not_to have_http_status(:not_found)
        expect(response).to have_http_status(:redirect)
      end

      it "does not raise I18n error for /users/auth/failure" do
        expect {
          get "/users/auth/failure"
        }.not_to raise_error
      end
    end
  end
end
