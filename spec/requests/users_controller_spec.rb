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
  end

  describe "GET /users/:id/two_factor_authentication" do
    it "returns http success" do
      get two_factor_authentication_user_path(user)
      expect(response).to have_http_status(:success)
    end
  end
end
