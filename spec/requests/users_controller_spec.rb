require 'rails_helper'

RSpec.describe UsersController, type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /users/:id" do
    it "returns http success" do
      get user_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /users/:id/edit" do
    it "returns http success" do
      get edit_user_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /users/:id" do
    context "with valid params" do
      it "updates the user and redirects" do
        patch user_path(user), params: { user: { username: "newname" } }
        expect(response).to redirect_to(user_path(user))
        follow_redirect!
        expect(response.body).to include("Your profile has been updated successfully")
        expect(user.reload.username).to eq("newname")
      end
    end

    context "with invalid params" do
      it "renders edit template" do
        patch user_path(user), params: { user: { username: "" } }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Username can&#39;t be blank")
      end
    end

    context "when changing preferred language by params" do
      it "does not update preferred language and not set cookie too" do
        get user_path(user, locale: :ja)
        expect(cookies[:locale]).to be_nil
        expect(I18n.locale).to eq(:ja)
        expect(user.reload.preferred_language).to be_blank
        # The page is displayed in Japanese
        expect(response.body).to include("さん、ようこそ！")
      end
    end

    context "when changing preferred language" do
      it "updates the preferred language and sets cookie locale" do
        patch user_path(user), params: { user: { preferred_language: "ja" } }
        expect(response).to redirect_to(user_path(user))
        follow_redirect!
        expect(user.reload.preferred_language).to eq("ja")
        expect(cookies[:locale]).to eq("ja")
        expect(I18n.locale).to eq(:ja)
      end
    end

    context "when changing preferred language to the same as current" do
      it "does not change the cookies locale" do
        user.update(preferred_language: "en")
        patch user_path(user), params: { user: { preferred_language: "en" } }
        expect(response).to redirect_to(user_path(user))
        follow_redirect!
        expect(user.reload.preferred_language).to eq("en")
        expect(cookies[:locale]).to eq("en")
        expect(I18n.locale).to eq(:en)
      end
    end

    context "when changing preferred language to a different one" do
      it "updates the cookies locale" do
        user.update(preferred_language: "en")
        patch user_path(user), params: { user: { preferred_language: "ja" } }
        expect(response).to redirect_to(user_path(user))
        follow_redirect!
        expect(user.reload.preferred_language).to eq("ja")
        expect(cookies[:locale]).to eq("ja")
        expect(I18n.locale).to eq(:ja)
      end
    end

    context "when changing preferred language to an unsupported locale" do
      it "does not change the preferred language and shows an error" do
        patch user_path(user), params: { user: { preferred_language: "unsupported" } }
        expect(response).to have_http_status(:ok)
        expect(user.reload.preferred_language).not_to eq("unsupported")
        expect(response.body).to include("Display Language is not a valid locale")
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
