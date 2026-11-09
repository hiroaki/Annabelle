
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remember me機能', type: :system do
  let(:user) { create(:user, :confirmed) }

  # ブラウザを閉じた状態を模擬するため、remember cookie だけを残す。
  # Capybara.reset_session! は remember cookie も削除するため使用しない。
  def preserve_remember_cookie
    cookies = page.driver.browser.cookies
    remember_cookie = cookies['remember_user_token']

    cookies.clear
    cookies.set(remember_cookie) if remember_cookie
  end

  it 'Remember meにチェックを入れてログインすると、ブラウザを閉じても自動的にログインされること' do
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    check 'Remember me'
    click_button I18n.t('devise.sessions.log_in')

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    expect(page.driver.browser.cookies['remember_user_token']).not_to be_nil
    preserve_remember_cookie

    visit root_path
    expect(page).to have_selector("[data-testid='current-user-display']")
  end

  it 'Remember meにチェックを入れずにログインすると、ブラウザを閉じるとログアウトされること' do
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    expect(page.driver.browser.cookies['remember_user_token']).to be_nil
    click_button I18n.t('devise.sessions.log_in')

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))

    preserve_remember_cookie

    visit root_path
    expect(page).not_to have_selector("[data-testid='current-user-display']")
  end
end
