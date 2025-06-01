require 'rails_helper'
require 'rotp'

RSpec.describe '2FA有効化フロー', type: :system do
  let(:username) { 'staff' }
  let(:password) { 'password123' }
  let(:user) { create(:user, username: username, password: password, password_confirmation: password, confirmed_at: Time.current) }

  before do
    driven_by(:cuprite)
    user # ユーザ作成
  end

  it '2FAを有効化できる' do
    # ログイン
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: password
    find('[data-testid="login-submit"]').click

    # 右上のユーザ名クリック
    find('[data-testid="current-user-display"]').click

    # 左のメニューをクリック
    find('[data-testid="configuration-menu-two-factor-authentication"]').click

    # 右のページ、 Enableボタン押下
    find('[data-testid="users_two_factor_authentication_enable"]').click

    secret = nil
    within('p', text: /please enter the following code manually/i) do
      secret = find('code').text
    end
    totp = ROTP::TOTP.new(secret)
    code = totp.now

    fill_in 'Code', with: code
    fill_in 'Enter your current password', with: password
    find('[data-testid="confirm-and-enable-two-factor"]').click

    expect(page).to have_selector('[data-testid="two-factor-enabled-message"]')
    expect(page).to have_selector('[data-testid="backup-codes-title"]')

    codes = all_testid('backup-code').map { |elem| elem.text }.select { |text| text.match?(/\A[a-f0-9]{32}\z/i) }
    expect(codes.size).to eq(5)
  end
end
