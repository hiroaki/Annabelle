# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User registration', type: :system do
  include ActionMailer::TestHelper

  let(:user_email) { 'newuser@example.com' }
  let(:user_password) { 'password123' }
  let(:user_username) { 'newuser_01' }

  context '新規登録画面の表示' do
    it 'サインアップページが表示されること' do
      visit new_user_registration_path
      expect(page).to have_selector('[data-testid="signup-title"]')
      expect(page).to have_selector('[data-testid="signup-email"]')
      expect(page).to have_selector('[data-testid="signup-username"]')
      expect(page).to have_selector('[data-testid="signup-password"]')
      expect(page).to have_selector('[data-testid="signup-password-confirm"]')
    end
  end

  context '正常系: ユーザー登録とメール認証' do
    it '有効な情報で登録すると確認メールが送信され、ログイン画面に遷移しメッセージが表示される' do
      visit new_user_registration_path
      find('[data-testid="signup-email"]').set(user_email)
      find('[data-testid="signup-username"]').set(user_username)
      find('[data-testid="signup-password"]').set(user_password)
      find('[data-testid="signup-password-confirm"]').set(user_password)
      perform_enqueued_jobs do
        find('[data-testid="signup-submit"]').click
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content(I18n.t('devise.registrations.signed_up_but_unconfirmed'))
        expect(ActionMailer::Base.deliveries.size).to eq(1)
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to include(user_email)
        expect(mail.subject).to match(/確認|Confirm/i)
      end
    end
  end

  context '異常系: バリデーションエラー' do
    it 'ユーザー名未入力の場合、エラーメッセージが表示される' do
      visit new_user_registration_path
      find('[data-testid="signup-email"]').set(user_email)
      find('[data-testid="signup-password"]').set(user_password)
      find('[data-testid="signup-password-confirm"]').set(user_password)
      find('[data-testid="signup-submit"]').click
      expect_error_message(User, :username, :blank)
    end

    it 'ユーザー名が不正な形式の場合、エラーメッセージが表示される' do
      visit new_user_registration_path
      find('[data-testid="signup-email"]').set(user_email)
      find('[data-testid="signup-username"]').set('invalid name!')
      find('[data-testid="signup-password"]').set(user_password)
      find('[data-testid="signup-password-confirm"]').set(user_password)
      find('[data-testid="signup-submit"]').click
      expect_error_message(User, :username, :invalid_format)
    end

    it 'パスワード不一致の場合、エラーメッセージが表示される' do
      visit new_user_registration_path
      find('[data-testid="signup-email"]').set(user_email)
      find('[data-testid="signup-username"]').set(user_username)
      find('[data-testid="signup-password"]').set(user_password)
      find('[data-testid="signup-password-confirm"]').set('wrongpassword')
      find('[data-testid="signup-submit"]').click
      # confirmationバリデーションのI18nは、attribute補間が必要なため他と呼び出し方が異なる
      # 例: errors.messages.confirmation: "doesn't match %{attribute}"
      expect_error_message(User, :password, :confirmation)
    end

    it 'メール未入力の場合、エラーメッセージが表示される' do
      visit new_user_registration_path
      find('[data-testid="signup-username"]').set(user_username)
      find('[data-testid="signup-password"]').set(user_password)
      find('[data-testid="signup-password-confirm"]').set(user_password)
      find('[data-testid="signup-submit"]').click
      expect_error_message(User, :email, :blank)
    end
  end

  context '言語スイッチャーの動作' do
    it 'バリデーションエラー時でも正しく動作すること' do
      visit new_user_registration_path

      # バリデーションエラーを発生させる
      find('[data-testid="signup-submit"]').click

      # エラーメッセージが表示される
      expect(page).to have_content("can't be blank")

      # 言語スイッチャーが表示されていることを確認
      expect(page).to have_link('日本語')

      # 言語を切り替え
      click_link '日本語'

      # 正しいパスにリダイレクトされる（404にならない）
      expect(page).to have_current_path('/ja/users/sign_up')
      # 登録画面特有の要素が表示されることを確認
      expect(page).to have_selector('[data-testid="signup-title"]')
      expect(page).to have_selector('[data-testid="signup-submit"]')
    end
  end
end
