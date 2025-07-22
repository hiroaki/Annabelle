# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'パスワードリセット', type: :system do
  include ActionMailer::TestHelper

  let(:user) { create(:user, :confirmed) }
  let(:new_password) { 'new_password123' }

  it 'パスワードをリセットできること' do
    # パスワードリセットの申請
    visit new_user_session_path
    click_link I18n.t('devise.shared.forgot_your_password')

    # リセット用メールアドレスを入力
    fill_in 'Email', with: user.email, id: 'user_email'

    perform_enqueued_jobs do
      find("[data-testid='password-reset-submit']").click
      expect(page).to have_content(I18n.t('devise.passwords.send_instructions'))

      # メールが送信されたことを確認
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(user.email)
      expect(mail.subject).to match(/#{I18n.t('devise.mailer.reset_password_instructions.subject')}/)

      # メールからリセットリンクを抽出してローカルURLに変換
      reset_link = mail.body.to_s.match(/href="([^"]+)"/)[1]
      reset_path = URI.parse(reset_link).path
      reset_query = URI.parse(reset_link).query
      visit "#{reset_path}?#{reset_query}"

      # 新しいパスワードを設定
      find("[data-testid='password-edit-new-password']").set(new_password)
      find("[data-testid='password-edit-confirm-password']").set(new_password)
      find("[data-testid='password-edit-submit']").click

      # パスワード変更成功のメッセージを確認
      expect(page).to have_content(I18n.t('devise.passwords.updated_not_active'))

      # 新しいパスワードでログインできることを確認
      fill_in 'Email', with: user.email
      fill_in 'Password', with: new_password
      click_button I18n.t('devise.sessions.log_in')

      expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    end
  end

  context '異常系' do
    it '登録されていないメールアドレスでリセット申請した場合' do
      visit new_user_password_path
      fill_in 'Email', with: 'unknown@example.com'
      find("[data-testid='password-reset-submit']").click
      expect(page).to have_content(I18n.t('errors.messages.not_found'))
    end

    it 'パスワード確認が一致しない場合' do
      visit new_user_session_path
      click_link I18n.t('devise.shared.forgot_your_password')
      fill_in 'Email', with: user.email

      perform_enqueued_jobs do
        find("[data-testid='password-reset-submit']").click
        mail = ActionMailer::Base.deliveries.last
        reset_link = mail.body.to_s.match(/href="([^"]+)"/)[1]
        reset_path = URI.parse(reset_link).path
        reset_query = URI.parse(reset_link).query
        visit "#{reset_path}?#{reset_query}"

        find("[data-testid='password-edit-new-password']").set('new_password123')
        find("[data-testid='password-edit-confirm-password']").set('different_password')
        find("[data-testid='password-edit-submit']").click

        expect(page).to have_content(I18n.t('errors.messages.confirmation', attribute: User.human_attribute_name('password')))
      end
    end

    it 'パスワードが短すぎる場合' do
      visit new_user_session_path
      click_link I18n.t('devise.shared.forgot_your_password')
      fill_in 'Email', with: user.email

      perform_enqueued_jobs do
        find("[data-testid='password-reset-submit']").click
        mail = ActionMailer::Base.deliveries.last
        reset_link = mail.body.to_s.match(/href="([^"]+)"/)[1]
        reset_path = URI.parse(reset_link).path
        reset_query = URI.parse(reset_link).query
        visit "#{reset_path}?#{reset_query}"

        find("[data-testid='password-edit-new-password']").set('short')
        find("[data-testid='password-edit-confirm-password']").set('short')
        find("[data-testid='password-edit-submit']").click

        expect(page).to have_content(I18n.t('errors.messages.too_short', count: 6))
      end
    end
  end

  describe '言語スイッチャーの動作' do
    it 'パスワードリセット申請時のバリデーションエラーでも正しく動作すること' do
      visit new_user_password_path

      # バリデーションエラーを発生させる
      find("[data-testid='password-reset-submit']").click

      # エラーメッセージが表示される
      expect(page).to have_content(I18n.t('errors.messages.blank'))

      # 言語スイッチャーが表示されていることを確認
      expect(page).to have_link('日本語')

      # 言語を切り替え
      click_link '日本語'

      # 正しいパスにリダイレクトされる（404にならない）
      expect(page).to have_current_path('/ja/users/password/new')
      expect(page).to have_selector("[data-testid='password-reset-submit']")
    end

    it 'パスワード更新時のバリデーションエラーでも正しく動作すること' do
      visit new_user_password_path
      fill_in 'Email', with: user.email

      perform_enqueued_jobs do
        find("[data-testid='password-reset-submit']").click
        mail = ActionMailer::Base.deliveries.last
        reset_link = mail.body.to_s.match(/href="([^"]+)"/)[1]
        reset_path = URI.parse(reset_link).path
        reset_query = URI.parse(reset_link).query
        visit "#{reset_path}?#{reset_query}"

        # バリデーションエラーを発生させる（パスワードなし）
        find("[data-testid='password-edit-submit']").click

        # エラーメッセージが表示される
        expect(page).to have_content(I18n.t('errors.messages.blank'))

        # 言語スイッチャーが表示されていることを確認
        expect(page).to have_link('日本語')

        # 言語を切り替え
        click_link '日本語'

        # パスワード更新の場合、トークンが失効するためログイン画面にリダイレクトされる
        # これは正常な動作（404にならない）
        expect(page).to have_current_path('/ja/users/sign_in')
        expect(page).to have_content('パスワード再設定メールからアクセスしてください')
      end
    end
  end
end
