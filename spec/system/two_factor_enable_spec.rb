require 'rails_helper'

RSpec.describe '2FA有効化フロー', type: :system do
  around do |example|
    with_env(
      'ENABLE_2FA' => '1',
      'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary',
      'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'det',
      'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'salt'
    ) do
      example.run
    end
  end

  let(:username) { 'staff' }
  let(:password) { 'password123' }
  let!(:user) { create(:user, username: username, password: password, password_confirmation: password, confirmed_at: Time.current) }

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

    expect(page).to have_selector('[data-testid="devise-sessions-two_factor_settings-title-title"]')
    expect(page).to have_selector('[data-testid="backup-codes-title"]')

    codes = all_testid('backup-code').map { |elem| elem.text }.select { |text| text.match?(/\A[a-f0-9]{32}\z/i) }
    expect(codes.size).to eq(5)
  end

  it '2FAを無効化できる' do
    # まず2FAを有効化
    user.update!(otp_required_for_login: true, otp_secret: User.generate_otp_secret, otp_backup_codes: %w[code1 code2 code3 code4 code5])

    # ログイン
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: password
    find('[data-testid="login-submit"]').click

    # 2FAコード入力
    totp = ROTP::TOTP.new(user.otp_secret)
    fill_in 'user_otp_attempt', with: totp.now
    find('[data-testid="otp-submit"]').click

    # 右上のユーザ名クリック
    find('[data-testid="current-user-display"]').click

    # 左のメニューをクリック
    find('[data-testid="configuration-menu-two-factor-authentication"]').click

    # 無効化ボタン押下（確認ダイアログで承認）
    accept_confirm do
      find('[data-testid="users_two_factor_authentication_disable"]').click
    end

    # 無効化完了のメッセージが表示されることを確認
    expect(page).to have_content('Successfully disabled two factor authentication')
    expect(page).to have_selector('.alert, .flash, [role="alert"]')

    # 2FA設定ページで有効化ボタンが表示されることを確認（無効化されたことの証明）
    expect(page).to have_selector('[data-testid="users_two_factor_authentication_enable"]')
  end

  describe 'バックアップコードでのログイン' do
    before do
      # 2FAを有効化して、画面に表示されるバックアップコードを取得
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find('[data-testid="login-submit"]').click

      find('[data-testid="current-user-display"]').click
      find('[data-testid="configuration-menu-two-factor-authentication"]').click
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

      # 画面に表示されたバックアップコードを取得
      @displayed_backup_codes = all('[data-testid="backup-code"]').map(&:text)

      # ログアウトして、バックアップコードでのログインテスト準備
      find('[data-testid="current-user-signout"]').click
    end

    it 'バックアップコードでログインできる' do
      # 表示されたバックアップコードの最初のものを使用
      first_backup_code = @displayed_backup_codes.first

      # ログイン
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find('[data-testid="login-submit"]').click

      # 2FAページが表示されることを確認
      expect(page).to have_selector('[data-testid="otp-input"]')
      expect(page).to have_selector('[data-testid="otp-submit"]')

      # バックアップコードでログイン
      fill_in 'user_otp_attempt', with: first_backup_code
      find('[data-testid="otp-submit"]').click

      # ログイン成功を確認
      expect(page).to have_content('Signed in successfully')
    end

    it 'バックアップコードは一度使うと使えなくなる' do
      first_backup_code = @displayed_backup_codes.first
      second_backup_code = @displayed_backup_codes.second

      # 1回目のログイン（成功）
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find('[data-testid="login-submit"]').click

      fill_in 'user_otp_attempt', with: first_backup_code
      find('[data-testid="otp-submit"]').click

      expect(page).to have_content('Signed in successfully')

      # ログアウト
      find('[data-testid="current-user-signout"]').click

      # 2回目のログイン（同じバックアップコードで失敗）
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find('[data-testid="login-submit"]').click

      fill_in 'user_otp_attempt', with: first_backup_code
      find('[data-testid="otp-submit"]').click

      # エラーメッセージが表示される
      expect(page).to have_content('Invalid authentication code')
      expect(page).to have_selector('[data-testid="otp-input"]')

      # 別のバックアップコードなら使える
      fill_in 'user_otp_attempt', with: second_backup_code
      find('[data-testid="otp-submit"]').click

      expect(page).to have_content('Signed in successfully')
    end

    it 'バックアップコードを使用後、残りのコード数が減る' do
      first_backup_code = @displayed_backup_codes.first

      # 使用前のバックアップコード数を確認
      user.reload
      initial_codes_count = user.otp_backup_codes.length

      # バックアップコードでログイン
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find('[data-testid="login-submit"]').click

      fill_in 'user_otp_attempt', with: first_backup_code
      find('[data-testid="otp-submit"]').click

      expect(page).to have_content('Signed in successfully')

      # データベースでバックアップコード数が減っていることを確認
      user.reload
      expect(user.otp_backup_codes.length).to eq(initial_codes_count - 1)
    end
  end
end
