require 'rails_helper'
require 'climate_control'

RSpec.describe 'TwoFactorSettings', type: :system do
  around do |example|
    ClimateControl.modify(
      'ENABLE_2FA' => '1',
      'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary',
      'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'det',
      'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'salt'
    ) do
      example.run
    end
  end

  let(:password) { 'password123' }
  let!(:user) { create(:user, password: password, password_confirmation: password, confirmed_at: Time.current) }

  before { Capybara.reset_sessions! }

  describe 'GET /two_factor_settings/new' do
    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        visit new_two_factor_settings_path
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('Log in')
      end
    end

    context 'when user is signed in' do
      before do
        visit new_user_session_path
        fill_in 'Email', with: user.email
        fill_in 'Password', with: password
        find_button('login-submit').click
      end

      context 'when 2FA is already enabled' do
        before do
          user.update!(otp_required_for_login: true, otp_secret: User.generate_otp_secret)
        end

        it 'redirects to dashboard with alert' do
          visit new_two_factor_settings_path
          expect(page).not_to have_current_path(new_two_factor_settings_path)
          expect(page).to have_content('Two factor authentication is already enabled')
          expect(page).to have_selector('.alert, .flash, [role="alert"]')
        end
      end

      context 'when 2FA is not enabled' do
        it 'renders the new template' do
          visit new_two_factor_settings_path
          expect(page).to have_selector('[data-testid="confirm-and-enable-two-factor"]')
          expect(page).to have_content(/scan.*qr.*code/i)
        end
      end
    end
  end

  describe 'GET /two_factor_settings/edit' do
    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        visit edit_two_factor_settings_path
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('Log in')
      end
    end

    context 'when user is signed in' do
      before do
        visit new_user_session_path
        fill_in 'Email', with: user.email
        fill_in 'Password', with: password
        find_button('login-submit').click
      end

      context 'when 2FA is not enabled' do
        before { user.update!(otp_required_for_login: false) }

        it 'redirects to new 2FA setup with alert' do
          visit edit_two_factor_settings_path
          expect(page).to have_current_path(new_two_factor_settings_path)
          expect(page).to have_content('Please enable two factor authentication first')
          expect(page).to have_selector('.alert, .flash, [role="alert"]')
        end
      end

      context 'when 2FA is enabled' do
        before { user.update!(otp_required_for_login: true, otp_secret: User.generate_otp_secret) }

        context 'when backup codes already generated' do
          before { user.update!(otp_backup_codes: %w[code1 code2 code3 code4 code5]) }

          it 'redirects to two factor authentication page with alert' do
            visit edit_two_factor_settings_path
            expect(page).to have_content('You have already seen your backup codes')
            expect(page).to have_selector('.alert, .flash, [role="alert"]')
          end
        end

        context 'when backup codes not generated' do
          before { user.update!(otp_backup_codes: []) }

          it 'generates backup codes and renders edit' do
            visit edit_two_factor_settings_path
            expect(page).to have_selector('[data-testid="backup-codes-title"]')
            codes = all('[data-testid="backup-code"]')
            expect(codes.size).to eq(5)
            codes.each { |el| expect(el.text).to match(/\A[a-f0-9]{32}\z/i) }
          end
        end
      end
    end
  end

  describe 'POST /two_factor_settings' do
    before do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find_button('login-submit').click
      visit new_two_factor_settings_path
    end

    let(:secret) do
      within('p', text: /please enter the following code manually/i) do
        find('code').text
      end
    end
    let(:totp) { ROTP::TOTP.new(secret) }

    context 'when password is incorrect' do
      it 'shows alert and stays on setup page' do
        fill_in 'Code', with: totp.now
        fill_in 'Enter your current password', with: 'wrong'
        find('[data-testid="confirm-and-enable-two-factor"]').click
        expect(page).to have_content('Incorrect password')
        expect(page).to have_selector('.alert, .flash, [role="alert"]', text: /incorrect.*password/i)
        expect(page).to have_selector('[data-testid="confirm-and-enable-two-factor"]')
      end
    end

    context 'when password is correct' do
      before { fill_in 'Enter your current password', with: password }

      context 'when OTP code is valid' do
        it 'enables 2FA and redirects to edit with notice' do
          fill_in 'Code', with: totp.now
          find('[data-testid="confirm-and-enable-two-factor"]').click
          expect(page).to have_selector('[data-testid="devise-sessions-two_factor_settings-title-title"]')
          expect(page).to have_selector('[data-testid="backup-codes-title"]')
          expect(page).to have_content('Successfully enabled two factor authentication')
        end
      end

      context 'when OTP code is invalid' do
        it 'shows alert and stays on setup page' do
          fill_in 'Code', with: '000000'
          find('[data-testid="confirm-and-enable-two-factor"]').click
          expect(page).to have_content('Incorrect Code')
          expect(page).to have_selector('.alert, .flash, [role="alert"]', text: /incorrect.*code/i)
          expect(page).to have_selector('[data-testid="confirm-and-enable-two-factor"]')
        end
      end
    end
  end

  describe 'DELETE /two_factor_settings' do
    before do
      user.update!(otp_required_for_login: true, otp_secret: User.generate_otp_secret, otp_backup_codes: %w[code1 code2 code3 code4 code5])
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find_button('login-submit').click

      totp = ROTP::TOTP.new(user.otp_secret)
      fill_in 'user_otp_attempt', with: totp.now
      find('[data-testid="otp-submit"]').click

      find_link('current-user-display').click
      find_link('configuration-menu-two-factor-authentication').click
    end

    context 'when disable_two_factor! succeeds' do
      it 'disables 2FA and redirects to authentication page with notice' do
        accept_confirm do
          find('[data-testid="users_two_factor_authentication_disable"]').click
        end
        expect(page).to have_content('Successfully disabled two factor authentication')
        expect(page).to have_selector('.alert, .flash, [role="alert"]')
      end
    end

    context 'when disable_two_factor! fails' do
      before do
        allow_any_instance_of(User).to receive(:disable_two_factor!).and_return(false)
      end

      it 'shows alert and stays on page' do
        accept_confirm do
          find('[data-testid="users_two_factor_authentication_disable"]').click
        end
        expect(page).to have_content('Could not disable two factor authentication')
        expect(page).to have_selector('.alert, .flash, [role="alert"]')
      end
    end
  end

  # 2FA有効化時の異常系（パスワード誤り・OTP誤り・空フォーム）
  describe 'Error handling during 2FA enablement' do
    before do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find_button('login-submit').click
      find_link('current-user-display').click
      find_link('configuration-menu-two-factor-authentication').click
      find_link('users_two_factor_authentication_enable').click
    end

    it 'shows error message when password is incorrect' do
      # 正しいOTPコードだがパスワードを間違えて送信した場合のエラー表示
      secret = nil
      within('p', text: /please enter the following code manually/i) do
        secret = find('code').text
      end
      totp = ROTP::TOTP.new(secret)
      fill_in 'Code', with: totp.now
      fill_in 'Enter your current password', with: 'wrong_password'
      find('[data-testid="confirm-and-enable-two-factor"]').click
      expect(page).to have_content('Incorrect password')
      expect(page).to have_selector('.alert, .flash, [role="alert"]', text: /incorrect.*password/i)
      expect(page).to have_selector('[data-testid="confirm-and-enable-two-factor"]')
      expect(page).to have_content(/scan.*qr.*code/i)
    end

    it 'shows error message when OTP code is incorrect' do
      # パスワードは正しいがOTPコードが間違っている場合のエラー表示
      fill_in 'Code', with: '000000'
      fill_in 'Enter your current password', with: password
      find('[data-testid="confirm-and-enable-two-factor"]').click
      expect(page).to have_content('Incorrect Code')
      expect(page).to have_selector('.alert, .flash, [role="alert"]', text: /incorrect.*code/i)
      expect(page).to have_selector('[data-testid="confirm-and-enable-two-factor"]')
    end

    it 'shows validation error when form is empty' do
      # フォーム未入力で送信した場合のバリデーションエラー表示
      find('[data-testid="confirm-and-enable-two-factor"]').click
      expect(page).to have_selector('[data-testid="confirm-and-enable-two-factor"]')
      expect(page).to have_selector('input:invalid, .error, .alert, [role="alert"]')
    end
  end

  describe 'JavaScript error detection' do
    before do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      find_button('login-submit').click
    end

    it 'does not have JavaScript errors on page load' do
      # 2FA設定画面のロード時にJSエラーが発生しないこと
      find_link('current-user-display').click
      find_link('configuration-menu-two-factor-authentication').click
      find_link('users_two_factor_authentication_enable').click
      expect(page).to have_selector('[data-testid="confirm-and-enable-two-factor"]')
      expect(page).to have_selector('input[name="two_fa[code]"]')
      expect(page).to have_selector('input[name="two_fa[password]"]')
      fill_in 'Code', with: '123456'
      fill_in 'Enter your current password', with: 'test'
      expect(find('input[name="two_fa[code]"]').value).to eq('123456')
      expect(find('input[name="two_fa[password]"]').value).to eq('test')
    end

    it 'does not have JavaScript errors on form submit' do
      # 2FA有効化フォーム送信時にJSエラーが発生しないこと
      find_link('current-user-display').click
      find_link('configuration-menu-two-factor-authentication').click
      find_link('users_two_factor_authentication_enable').click
      fill_in 'Code', with: '000000'
      fill_in 'Enter your current password', with: 'wrong'
      find('[data-testid="confirm-and-enable-two-factor"]').click
      expect(page).to have_selector('input[name="two_fa[code]"]')
      expect(page).to have_selector('input[name="two_fa[password]"]')
      expect(page).to have_selector('[data-testid="confirm-and-enable-two-factor"]')
    end
  end
end
