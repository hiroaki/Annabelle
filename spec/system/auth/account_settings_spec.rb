# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'アカウント設定', type: :system do
  include ActionMailer::TestHelper
  let(:user) { create(:user, :confirmed, password: 'current_password') }

  before do
    login_as(user)
    visit edit_user_registration_path
  end

  describe 'メールアドレスの変更' do
    it '現在のパスワードを入力して更新できること' do
      find("[data-testid='account-email']").set('new_email@example.com')
      find("[data-testid='account-current-password']").set('current_password')

      perform_enqueued_jobs do
        find("[data-testid='account-update-submit']").click

        expect(page).to have_content(I18n.t('devise.registrations.update_needs_confirmation'))
        expect(ActionMailer::Base.deliveries.last.to).to include('new_email@example.com')
      end
    end

    it '現在のパスワードなしでは更新できないこと' do
      find("[data-testid='account-email']").set('new_email@example.com')
      find("[data-testid='account-update-submit']").click

      expect(page).to have_content(I18n.t('errors.messages.blank'))
    end
  end

  describe 'パスワードの変更' do
    let(:new_password) { 'new_password123' }

    it '全てのパスワードフィールドを正しく入力して更新できること' do
      find("[data-testid='account-new-password']").set(new_password)
      find("[data-testid='account-confirm-password']").set(new_password)
      find("[data-testid='account-current-password']").set('current_password')
      find("[data-testid='account-update-submit']").click

      expect(page).to have_content(I18n.t('devise.registrations.updated'))

      # 新しいパスワードでログインできることを確認
      click_on 'current-user-signout'
      fill_in 'Email', with: user.email
      fill_in 'Password', with: new_password
      click_button I18n.t('devise.sessions.log_in')

      expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    end

    it 'パスワード確認が一致しない場合は更新できないこと' do
      find("[data-testid='account-new-password']").set(new_password)
      find("[data-testid='account-confirm-password']").set('different_password')
      find("[data-testid='account-current-password']").set('current_password')
      find("[data-testid='account-update-submit']").click

      expect(page).to have_content(I18n.t('errors.messages.confirmation', attribute: User.human_attribute_name('password')))
    end

    it '現在のパスワードが間違っている場合は更新できないこと' do
      find("[data-testid='account-new-password']").set(new_password)
      find("[data-testid='account-confirm-password']").set(new_password)
      find("[data-testid='account-current-password']").set('wrong_password')
      find("[data-testid='account-update-submit']").click

      expect(page).to have_content(I18n.t('errors.messages.invalid'))
    end
  end

  if Devise.mappings[:user].omniauthable?
    describe 'OAuth連携' do
      it 'GitHubアカウントと連携できること' do
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
          provider: 'github',
          uid: '123545',
          info: { email: user.email }
        )

        find("[data-testid='account-link-github']").click
        expect(page).to have_content(I18n.t('devise.omniauth_callbacks.provider.linked', provider: 'GitHub'))
        expect(page).to have_selector("[data-testid='account-unlink-github']")

        OmniAuth.config.test_mode = false
      end
    end
  end

  describe 'アカウントの削除' do
    it '確認ダイアログで承認するとアカウントを削除できること' do
      accept_confirm do
        find("[data-testid='account-cancel']").click
      end

      # ログインページに遷移することを確認
      expect(page).to have_current_path(new_user_session_path)
      # リダイレクト先でメッセージが表示されることを確認
      expect(page).to have_content(I18n.t('devise.registrations.destroyed'))
      # ユーザーが削除されていることを確認
      expect(User.exists?(user.id)).to be false
    end

    it '確認ダイアログでキャンセルするとアカウントは削除されないこと' do
      dismiss_confirm do
        find("[data-testid='account-cancel']").click
      end

      expect(page).to have_current_path(edit_user_registration_path)
      expect(User.exists?(user.id)).to be true
    end
  end

  describe '言語スイッチャーの動作' do
    it 'バリデーションエラー時でも正しく動作すること' do
      # 現在のパスワードなしで更新を試行（バリデーションエラー）
      find("[data-testid='account-email']").set('new_email@example.com')
      find("[data-testid='account-update-submit']").click

      # エラーメッセージが表示される
      expect(page).to have_content(I18n.t('errors.messages.blank'))

      # 言語スイッチャーが表示されていることを確認
      expect(page).to have_link('日本語')

      # 言語を切り替え
      click_link '日本語'

      # 正しいパスにリダイレクトされる（404にならない）
      expect(page).to have_current_path('/ja/users/edit')
      # アカウント設定画面特有の要素が表示されることを確認
      expect(page).to have_selector("[data-testid='account-settings-title']")
      expect(page).to have_selector("[data-testid='account-update-submit']")
    end
  end
end
