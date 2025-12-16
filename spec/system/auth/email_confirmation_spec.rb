# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '認証メールフロー', type: :system do
  include ActionMailer::TestHelper

  let(:user) { create(:user, confirmed_at: nil) }
  let(:confirmation_token) { user.confirmation_token }

  it 'メール確認後に初回ログインができること' do
    # メール確認のリンクにアクセス
    visit user_confirmation_path(confirmation_token: confirmation_token)
    within('[data-flash-message-container]') do
      expect(page).to have_selector('.flash-message-text')
      expect(page).to have_content(I18n.t('devise.confirmations.confirmed'))
    end

    # 確認完了後、ログインできることを確認
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button I18n.t('devise.sessions.log_in')

    within('[data-flash-message-container]') do
      expect(page).to have_selector('.flash-message-text')
      expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    end
  end

  it '確認メールを再送できること' do
    visit new_user_confirmation_path
    fill_in 'Email', with: user.email

    perform_enqueued_jobs do
      click_button I18n.t('devise.confirmations.resend_confirmation_instructions')

      expect(page).to have_content(I18n.t('devise.confirmations.send_instructions'))

      # メールが送信されたことを確認
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(user.email)
      expect(mail.subject).to match(/#{I18n.t('devise.mailer.confirmation_instructions.subject')}/)
    end
  end

  it '存在しないメールアドレスで確認メールを再送しようとするとエラーになること' do
    visit new_user_confirmation_path
    fill_in 'Email', with: 'nonexistent@example.com'
    click_button I18n.t('devise.confirmations.resend_confirmation_instructions')

    expect(page).to have_content(I18n.t('errors.messages.not_found'))
  end

  it '既に確認済みのメールアドレスで確認メールを再送しようとするとエラーになること' do
    confirmed_user = create(:user, :confirmed)

    visit new_user_confirmation_path
    fill_in 'Email', with: confirmed_user.email
    click_button I18n.t('devise.confirmations.resend_confirmation_instructions')

    expect(page).to have_content(I18n.t('errors.messages.already_confirmed'))
  end

  describe '言語スイッチャーの動作' do
    it '確認メール再送時のバリデーションエラーでも正しく動作すること' do
      visit new_user_confirmation_path

      # バリデーションエラーを発生させる（メールアドレスなし）
      click_button I18n.t('devise.confirmations.resend_confirmation_instructions')

      # エラーメッセージが表示される
      expect(page).to have_content(I18n.t('errors.messages.blank'))

      # 言語スイッチャーが表示されていることを確認
      expect(page).to have_link('日本語')

      # 言語を切り替え
      click_link '日本語'

      # 正しいパスにリダイレクトされる（404にならない）
      expect(page).to have_current_path('/ja/users/confirmation/new')
      expect(page).to have_button('確認メールを再送')
    end

    it '無効なトークンでのメール確認失敗でも正しく動作すること' do
      # 無効なトークンでアクセス
      visit user_confirmation_path(confirmation_token: 'invalid_token')

      # エラーメッセージが表示される
      expect(page).to have_content(I18n.t('errors.messages.invalid'))

      # 言語スイッチャーが表示されていることを確認
      expect(page).to have_link('日本語')

      # 言語を切り替え
      click_link '日本語'

      # 正しいパスにリダイレクトされる（404にならない）
      expect(page).to have_current_path('/ja/users/confirmation/new')
      expect(page).to have_button('確認メールを再送')
    end
  end
end
