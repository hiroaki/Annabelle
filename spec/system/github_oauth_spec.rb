# spec/system/github_oauth_spec.rb
require 'rails_helper'

RSpec.describe "GitHub OAuth 連携", type: :system, js: true do
  before do
    driven_by(:cuprite_custom)
  end

  context "ユーザーがログインしていない場合" do
    it "GitHubログインで新規ユーザーが作成され、ログイン状態になる" do
      mock_github_auth

      visit new_user_session_path
      click_button "Sign in with GitHub"

      expect(page).to have_current_path(edit_user_registration_path)
      expect(page).to have_content("Successfully authenticated from github account.")
    end
  end

  context "ログイン中のユーザーが GitHub と未連携の場合" do
    let(:user) { create(:user, provider: nil, uid: nil) }

    before do
      login_as(user, scope: :user)  # Wardenヘルパー
    end

    it "GitHubと連携され、プロフィール編集ページに遷移する" do
      mock_github_auth

      visit edit_user_registration_path
      find("#oauth-button-github").click # click_button "GitHubアカウントと連携"

      expect(page).to have_content("GitHub との連携が成功しました。")
      user.reload
      expect(user.provider).to eq("github")
      expect(user.uid).to eq("new_uid")
    end
  end

  context "ログイン中のユーザーが別の GitHub アカウントと既に連携済みの場合" do
    let(:user) { create(:user, provider: nil, uid: nil) }

    before do
      login_as(user, scope: :user)
    end

    it "連携は変更されず、警告が表示される" do
      mock_github_auth(uid: "old_uid")

      visit edit_user_registration_path

      user.update!(provider: "github", uid: "new_uid")  # 違うuid

      find("#oauth-button-github").click # click_button "GitHubアカウントと連携"
      expect(page).to have_content("既に別の GitHub アカウントと連携されています。変更はキャンセルされました。")
      user.reload
      expect(user.uid).to eq("new_uid")
    end
  end
end
