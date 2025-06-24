require 'rails_helper'

RSpec.describe UsersController, type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /users/:id" do
    it "returns http success" do
      get dashboard_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /users/:id/edit" do
    it "returns http success" do
      get edit_profile_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /users/:id" do
    context "with valid params" do
      it "updates the user and redirects to edit page" do
        patch dashboard_path, params: { user: { username: "newname" } }
        expect(response).to redirect_to(edit_profile_path)
        follow_redirect!
        expect(response.body).to include("Your profile has been updated successfully")
        expect(user.reload.username).to eq("newname")
      end
    end

    context "with invalid params" do
      it "renders edit template" do
        patch dashboard_path, params: { user: { username: "" } }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Username can&#39;t be blank")
      end
    end

    context "when accessing with locale in URL" do
      it "displays page in requested locale without changing user preference" do
        get edit_profile_path(locale: :ja)
        expect(I18n.locale).to eq(:ja)
        expect(user.reload.preferred_language).to be_blank
        expect(response).to have_http_status(:success)
      end
    end

    context "when changing preferred language via form" do
      it "updates the preferred language and redirects to appropriate locale URL" do
        patch dashboard_path, params: { user: { preferred_language: "ja" } }
        expect(response).to redirect_to("/ja/profile/edit")
        expect(user.reload.preferred_language).to eq("ja")
      end

      it "redirects to default URL when setting to English" do
        patch dashboard_path, params: { user: { preferred_language: "en" } }
        expect(response).to redirect_to("/en/profile/edit")
        expect(user.reload.preferred_language).to eq("en")
      end
    end

    context "when language setting doesn't change" do
      it "redirects to edit page without locale change" do
        user.update(preferred_language: "en")
        patch dashboard_path, params: { user: { preferred_language: "en" } }
        expect(response).to redirect_to(edit_profile_path)
        expect(user.reload.preferred_language).to eq("en")
      end
    end

    context "when changing preferred language to an unsupported locale" do
      it "does not change the preferred language and shows an error" do
        patch dashboard_path, params: { user: { preferred_language: "unsupported" } }
        expect(response).to have_http_status(:ok)
        expect(user.reload.preferred_language).not_to eq("unsupported")
        expect(response.body).to include("Display Language is not a valid locale")
      end
    end

    # 仕様に基づく包括的テスト
    describe "comprehensive language change behavior" do
      before do
        I18n.default_locale = :en
        allow(I18n).to receive(:available_locales).and_return([:ja, :en])
      end

      context "when browser language is ja" do
        [
          # [user_setting, form_selection, expected_locale]
          ["ja", "ja", "ja"],
          ["ja", "en", "en"], # en is default locale, but test env includes /en/ prefix
          ["ja", "", "ja"], # empty means browser setting (ja)
          ["en", "ja", "ja"],
          ["en", "en", "en"],
          ["en", "", "ja"], # empty means browser setting (ja)
          ["", "ja", "ja"],
          ["", "en", "en"],
          ["", "", "ja"], # empty means browser setting (ja)
        ].each do |user_setting, form_selection, expected_locale|
          it "redirects to correct path when user setting is '#{user_setting}' and form selection is '#{form_selection}'" do
            user.update(preferred_language: user_setting)
            
            # HTTPヘッダーを設定してリクエスト
            patch dashboard_path, 
                  params: { user: { preferred_language: form_selection } }, 
                  headers: { 'HTTP_ACCEPT_LANGUAGE' => 'ja,en-US;q=0.9,en;q=0.8' }
            
            expect(user.reload.preferred_language).to eq(form_selection)
            
            # すべてのケースでリダイレクトが発生する（新しい実装では常にリダイレクト）
            expect(response).to have_http_status(:redirect)
            
            # テスト環境では常にロケールプレフィックスが付く
            expect(response.location).to match(%r{/#{expected_locale}/users/\d+/edit$})
          end
        end
      end

      context "when browser language is en" do
        [
          # [user_setting, form_selection, expected_locale]
          ["ja", "ja", "ja"],
          ["ja", "en", "en"],
          ["ja", "", "en"], # empty means browser setting (en)
          ["en", "ja", "ja"],
          ["en", "en", "en"],
          ["en", "", "en"], # empty means browser setting (en)
          ["", "ja", "ja"],
          ["", "en", "en"],
          ["", "", "en"], # empty means browser setting (en)
        ].each do |user_setting, form_selection, expected_locale|
          it "redirects to correct path when user setting is '#{user_setting}' and form selection is '#{form_selection}'" do
            user.update(preferred_language: user_setting)
            
            # HTTPヘッダーを設定してリクエスト  
            patch dashboard_path, 
                  params: { user: { preferred_language: form_selection } }, 
                  headers: { 'HTTP_ACCEPT_LANGUAGE' => 'en-US,en;q=0.9' }
            
            expect(user.reload.preferred_language).to eq(form_selection)
            
            # すべてのケースでリダイレクトが発生する（新しい実装では常にリダイレクト）
            expect(response).to have_http_status(:redirect)
            
            # テスト環境では常にロケールプレフィックスが付く
            expect(response.location).to match(%r{/#{expected_locale}/users/\d+/edit$})
          end
        end
      end
    end

    describe "locale-specific scenarios" do
      it "redirects to default URL when changing to English from Japanese URL" do
        user.update(preferred_language: "ja")
        patch dashboard_path, params: { user: { preferred_language: "en" } }
        
        expect(response).to have_http_status(:redirect)
        expect(response.location).to match(%r{/en/users/\d+/edit$})
        expect(user.reload.preferred_language).to eq("en")
      end

      it "redirects to Japanese URL when changing to Japanese from English URL" do
        user.update(preferred_language: "en")
        patch dashboard_path, params: { user: { preferred_language: "ja" } }
        
        expect(response).to have_http_status(:redirect)
        expect(response.location).to match(%r{/ja/users/\d+/edit$})
        expect(user.reload.preferred_language).to eq("ja")
      end

      it "handles empty string selection based on browser language" do
        patch dashboard_path, 
              params: { user: { preferred_language: "" } },
              headers: { 'HTTP_ACCEPT_LANGUAGE' => 'ja,en-US;q=0.9,en;q=0.8' }
        
        expect(response).to have_http_status(:redirect)
        expect(response.location).to match(%r{/ja/users/\d+/edit$})
        expect(user.reload.preferred_language).to eq("")
      end
    end
  end

  describe "GET /users/:id/two_factor_authentication" do
    it "returns http success" do
      get two_factor_authentication_user_path(user)
      expect(response).to have_http_status(:success)
    end
  end
end
