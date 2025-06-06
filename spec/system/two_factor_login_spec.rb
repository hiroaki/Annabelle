# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Two-factor authentication login', type: :system do
  let(:user) { FactoryBot.create(:user, :with_otp) }

  it 'allows login with correct OTP' do
    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    find('[data-testid="login-submit"]').click

    # Should be on 2FA page
    expect(page).to have_selector('[data-testid="otp-input"]')
    expect(page).to have_selector('[data-testid="otp-submit"]')

    fill_in 'user_otp_attempt', with: user.current_otp
    find('[data-testid="otp-submit"]').click

    expect(page).to have_content(I18n.t('devise.sessions.signed_in')).or have_content(I18n.t('devise.sessions.signed_in', locale: :en))
  end

  it 'shows error with incorrect OTP' do
    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    find('[data-testid="login-submit"]').click

    fill_in 'user_otp_attempt', with: '000000'
    find('[data-testid="otp-submit"]').click

    expect(page).to have_content(I18n.t('devise.sessions.invalid_otp')).or have_content(I18n.t('devise.sessions.invalid_otp', locale: :en)).or have_content('Invalid two-factor code.')
    expect(page).to have_selector('[data-testid="otp-input"]')
  end

  # Add more scenarios as needed (backup code, non-2FA user, etc)
end
