# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '認証メールフロー', type: :system do
  include ActionMailer::TestHelper

  let(:user) { create(:user, confirmed_at: nil) }
  let(:confirmation_token) { user.confirmation_token }

  it 'メール確認後に初回ログインができること' do
    # メール確認のリンクにアクセス
    visit user_confirmation_path(confirmation_token: confirmation_token)
    expect(page).to have_content(I18n.t('devise.confirmations.confirmed'))

    # 確認完了後、ログインできることを確認
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button I18n.t('devise.sessions.log_in')

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
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
end
