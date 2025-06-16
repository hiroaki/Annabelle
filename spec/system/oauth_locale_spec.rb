# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OAuth Language Processing', type: :system, js: true do
  include OmniauthMacros

  before do
    I18n.default_locale = LocaleConfiguration.default_locale
    allow(I18n).to receive(:available_locales).and_return(LocaleConfiguration.available_locales)
  end

  after do
    clear_omniauth_mock
  end

  def visit_signin_with_locale_and_oauth(locale)
    if locale == :ja
      visit '/ja/users/sign_in'
      expect(page).to have_button('ログイン')
    else
      visit '/en/users/sign_in'
      expect(page).to have_button('Log in')
    end

    find('[data-testid="signin_with_github"]').click
  end

  def visit_signin_with_lang_param_and_oauth(lang)
    # 明示的ロケール必須化により、ロケール付きパスでアクセス
    visit "/#{lang}/users/sign_in"

    if lang == 'ja'
      expect(page).to have_button('ログイン')
    else
      expect(page).to have_button('Log in')
    end

    find('[data-testid="signin_with_github"]').click
  end

  describe 'GitHub OAuth language retention' do
    context 'when OAuth is initiated from Japanese URL' do
      it 'displays in Japanese after OAuth authentication' do
        mock_github_auth(uid: "oauth_ja_uid", email: "oauth_ja@example.com")

        visit_signin_with_locale_and_oauth(:ja)

        # OAuth認証後のページで日本語表示を確認
        expect(page).to have_current_path(edit_user_registration_path(locale: :ja))

        # ユーザー作成確認
        user = User.find_by(email: "oauth_ja@example.com")
        expect(user).to be_present

        # 新規ユーザーなので編集画面に遷移
        # 日本語で表示されていることを確認（プロフィール編集ページの特定の要素）
        expect(page).to have_content('アカウント設定')
      end
    end

    context 'when OAuth is initiated with lang parameter' do
      it 'displays in specified language after OAuth authentication' do
        mock_github_auth(uid: "oauth_lang_uid", email: "oauth_lang@example.com")

        visit_signin_with_lang_param_and_oauth('ja')

        # OAuth認証後に日本語で表示されることを確認
        user = User.find_by(email: "oauth_lang@example.com")
        expect(user).to be_present

        # 日本語ロケールパスに遷移していることを確認
        expect(page).to have_current_path(edit_user_registration_path(locale: :ja))

        # 日本語コンテンツが表示されることを確認
        expect(page).to have_content('アカウント設定')
      end
    end

    context 'when existing user uses OAuth authentication' do
      let!(:existing_user) { create(:user, email: "existing_oauth@example.com", preferred_language: '') }

      it 'displays in appropriate language from Japanese URL OAuth authentication' do
        mock_github_auth(uid: "existing_oauth_uid", email: existing_user.email)

        visit_signin_with_locale_and_oauth(:ja)

        # ログイン後、日本語ロケールのルートページに遷移することを確認
        expect(page).to have_current_path(root_path(locale: :ja))

        # 日本語表示を確認
        expect(page).to have_content('投稿')
      end
    end

    context 'when existing user with Japanese preference uses OAuth from English page' do
      let!(:existing_user) { create(:user, email: "existing_oauth_en@example.com", preferred_language: 'ja') }

      it 'displays in English (OAuth context) not Japanese (user preference)' do
        mock_github_auth(uid: "existing_oauth_en_uid", email: existing_user.email)

        # 明示的ロケール必須化により、英語ロケール付きパスでアクセス
        visit '/en/users/sign_in'
        expect(page).to have_button('Log in')
        find('[data-testid="signin_with_github"]').click

        # ログイン後、英語ロケールのルートページに遷移することを確認
        # ユーザー設定(ja)ではなく、OAuth開始時のコンテキスト(en)を優先
        expect(page).to have_current_path(root_path(locale: 'en'))  # 明示的に英語ロケール

        # 英語表示を確認
        expect(page).to have_content('Post')  # not '投稿'
      end
    end
  end
end
