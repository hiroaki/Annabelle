# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Two-factor authentication login', type: :system do
  let(:user) { FactoryBot.create(:user, :with_otp) }

  before do
    # セッションをクリアして他のテストの影響を排除
    Capybara.reset_sessions!
    # 確実に英語ロケールに設定してテスト間の状態漏れを防ぐ
    I18n.locale = :en
  end

  after do
    # テスト後にデフォルトロケールに戻す
    I18n.locale = I18n.default_locale
  end

  context 'with English locale' do
    around do |example|
      # テスト実行中は必ず英語ロケールを維持
      I18n.with_locale(:en) do
        # セッションクリアとロケール設定を確実に実行
        Capybara.reset_sessions!
        Rails.logger.debug "Two-factor test: Set I18n.locale to #{I18n.locale}"
        example.run
      end
    end

    it 'allows login with correct OTP' do
      # ロケール確認のためのデバッグ出力
      Rails.logger.debug "Test start: I18n.locale = #{I18n.locale}"

      # 英語ロケールでアクセス
      visit new_user_session_path(locale: :en)
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: user.password
      find('[data-testid="login-submit"]').click

      # Should be on 2FA page
      expect(page).to have_selector('[data-testid="otp-input"]')
      expect(page).to have_selector('[data-testid="otp-submit"]')

      fill_in 'user_otp_attempt', with: user.current_otp
      find('[data-testid="otp-submit"]').click

      # 英語コンテキストなので、必ず英語のメッセージを期待
      expect(page).to have_content('Signed in successfully.')
    end

    it 'shows error with incorrect OTP' do
      # ロケール確認のためのデバッグ出力
      Rails.logger.debug "Test start: I18n.locale = #{I18n.locale}"

      # 英語ロケールでアクセス
      visit new_user_session_path(locale: :en)
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: user.password
      find('[data-testid="login-submit"]').click

      fill_in 'user_otp_attempt', with: '000000'
      find('[data-testid="otp-submit"]').click

      # 英語コンテキストなので、必ず英語のエラーメッセージを期待
      expect(page).to have_content('Invalid authentication code.')
      expect(page).to have_selector('[data-testid="otp-input"]')
    end
  end
end
