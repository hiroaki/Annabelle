require 'rails_helper'

RSpec.describe "GitHub OAuth連携", type: :system, js: true do
  before do
    driven_by(:cuprite_custom)
  end

  def visit_signin_and_click_github
    visit new_user_session_path
    click_button "Sign in with GitHub"
  end

  describe "未ログイン状態のGitHub認証" do
    context "新規ユーザーがGitHubで認証する場合" do
      it "新規ユーザーが作成され、ログイン状態になる" do
        mock_github_auth(uid: "abc123", email: "newuser@example.com")

        visit_signin_and_click_github

        expect(page).to have_current_path(edit_user_registration_path)
        expect(page).to have_content("Successfully authenticated from github account.")

        user = User.find_by(email: "newuser@example.com")
        expect(user).to be_present
        expect(user.provider).to eq("github")
        expect(user.uid).to eq("abc123")
      end
    end

    context "未確認の既存ユーザーのメールと一致する場合" do
      it "既存ユーザーを削除し、新規ユーザーが作成される" do
        unconfirmed = create(:user, email: "ghost@example.com", confirmed_at: nil)
        mock_github_auth(uid: "uid789", email: "ghost@example.com")

        expect {
          visit_signin_and_click_github
        }.not_to change(User, :count)

        expect(User.exists?(unconfirmed.id)).to be_falsey
        new_user = User.find_by(email: "ghost@example.com")
        expect(new_user.uid).to eq("uid789")
      end
    end

    context "GitHubからメールアドレスが返ってこない場合" do
      it "ユーザー作成が失敗し、エラーメッセージが表示される" do
        mock_github_auth(uid: "uid999", email: nil)

        visit_signin_and_click_github

        expect(page).to have_current_path(new_user_registration_path)
        expect(page).to have_content("GitHub 認証に失敗しました。")
      end
    end
  end

  describe "ログイン中ユーザーのGitHub連携" do
    let(:user) { create(:user, provider: nil, uid: nil) }

    before do
      login_as(user, scope: :user)
    end

    context "GitHub未連携状態から連携する場合" do
      it "連携が成功し、ユーザーにGitHub情報が保存される" do
        mock_github_auth(uid: "new_uid", email: user.email)

        visit edit_user_registration_path
        find("#oauth-button-github").click

        expect(page).to have_content("GitHub との連携が成功しました。")
        user.reload
        expect(user.provider).to eq("github")
        expect(user.uid).to eq("new_uid")
      end
    end

    context "すでに他のGitHubアカウントと連携済みの場合" do
      it "連携は変更されず、警告メッセージが表示される" do
        mock_github_auth(uid: "new_uid")

        visit edit_user_registration_path

        user.update!(provider: "github", uid: "old_uid")

        find("#oauth-button-github").click

        expect(page).to have_content("既に別の GitHub アカウントと連携されています。変更はキャンセルされました。")
        user.reload
        expect(user.uid).to eq("old_uid")
      end
    end
  end

  describe "GitHubアカウントの重複利用" do
    let!(:existing_user) { create(:user, provider: "github", uid: "dupe_uid") }

    it "同じuidで認証すると既存ユーザーがログインされる" do
      mock_github_auth(uid: "dupe_uid", email: existing_user.email)

      visit_signin_and_click_github

      expect(page).to have_content("Successfully authenticated from github account.")
      expect(User.where(uid: "dupe_uid").count).to eq(1)
    end
  end

  describe "異常系: username生成に10回失敗する場合" do
    it "例外が発生してもロールバックされ、認証失敗として扱われる" do
      allow(SecureRandom).to receive(:alphanumeric).and_return("conflict")
      create(:user, username: "user_conflict")

      unconfirmed = create(:user, email: "ghost@example.com", confirmed_at: nil)
      mock_github_auth(uid: "fail_uid", email: "ghost@example.com")

      visit_signin_and_click_github

      expect(page).to have_current_path(new_user_registration_path)
      expect(page).to have_content("GitHub 認証に失敗しました。")

      expect(User.exists?(unconfirmed.id)).to be true
      expect(User.find_by(uid: "fail_uid")).to be_nil
    end
  end
end
