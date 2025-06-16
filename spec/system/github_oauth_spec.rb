# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GitHub OAuth連携", type: :system, js: true do
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

        user = User.find_by(email: "newuser@example.com")
        expect(user).to be_present

        # Authorizationを使ってproviderとuidを確認
        authorization = user.authorizations.find_by(provider: "github", uid: "abc123")
        expect(authorization).to be_present
      end
    end

    context "登録済みの既存ユーザーがGitHubで認証する場合" do
      it "既存ユーザーがログインされ、トップページ (root_path) に遷移すること" do
        existing_user = create(:user, email: "existing@example.com")
        mock_github_auth(uid: "existing_uid", email: existing_user.email)

        visit_signin_and_click_github

        expect(page).to have_current_path(root_path)
        expect(page).to have_content(
          I18n.t("devise.omniauth_callbacks.provider.success", provider: "GitHub")
        )
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

        # Authorizationを使ってuidを確認
        authorization = new_user.authorizations.find_by(uid: "uid789")
        expect(authorization).to be_present
      end
    end

    context "GitHubからメールアドレスが返ってこない場合" do
      it "ユーザー作成が失敗し、エラーメッセージが表示される" do
        mock_github_auth(uid: "uid999", email: nil)

        visit_signin_and_click_github

        expect(page).to have_current_path(new_user_registration_path)
        expect(page).to have_content(
          I18n.t("devise.omniauth_callbacks.failure", kind: "GitHub")
        )
      end
    end
  end

  describe "ログイン中ユーザーのGitHub連携" do
    let(:user) { create(:user) }  # providerとuidは既にnilの状態で作成

    before do
      login_as(user, scope: :user)
    end

    context "GitHub未連携状態から連携する場合" do
      it "連携が成功し、ユーザーにGitHub情報が保存される" do
        mock_github_auth(uid: "new_uid", email: user.email)

        visit edit_user_registration_path
        find("#oauth-button-github").click

        expect(page).to have_content(
          I18n.t("devise.omniauth_callbacks.provider.success", provider: "GitHub")
        )
        user.reload

        # Authorizationを使ってproviderとuidを確認
        authorization = user.authorizations.find_by(provider: "github", uid: "new_uid")
        expect(authorization).to be_present
      end
    end

    context "すでに他のGitHubアカウントと連携済みの場合" do
      it "連携は変更されず、警告メッセージが表示される" do
        mock_github_auth(uid: "new_uid")

        visit edit_user_registration_path

        # Authorizationを使って古い情報を更新
        user.authorizations.create!(provider: "github", uid: "old_uid")

        find("#oauth-button-github").click

        expect(page).to have_content(
          I18n.t("devise.omniauth_callbacks.provider.already_linked", provider: "GitHub")
        )
        user.reload

        # 古いAuthorizationが保持されているか確認
        authorization = user.authorizations.find_by(uid: "old_uid")
        expect(authorization).to be_present
      end
    end
  end

  describe "GitHubアカウントの重複利用" do
    let!(:existing_user) { create(:user) }
    let!(:existing_authorization) { create(:authorization, user: existing_user, provider: "github", uid: "dupe_uid") }

    it "同じuidで認証すると既存ユーザーがログインされる" do
      mock_github_auth(uid: "dupe_uid", email: existing_user.email)

      visit_signin_and_click_github

      expect(page).to have_content(
        I18n.t("devise.omniauth_callbacks.provider.success", provider: "GitHub")
      )

      # Authorizationを使ってuidを確認
      authorization = existing_user.authorizations.find_by(uid: "dupe_uid")
      expect(authorization).to be_present
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
      expect(page).to have_content(
        I18n.t("devise.omniauth_callbacks.failure", kind: "GitHub")
      )

      expect(User.exists?(unconfirmed.id)).to be true
      expect(Authorization.exists?(uid: "fail_uid")).to be false
    end
  end
end
