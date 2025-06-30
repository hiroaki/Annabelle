# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Omniauth OAuth locale handling', type: :system do
  let(:user) { create(:user, :confirmed, preferred_language: 'ja') }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: :github,
      uid: '12345',
      info: { email: 'test@example.com' }
    )
  end

  after do
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.test_mode = false
  end

  # 既存ユーザーがアカウント連携した場合、画面の言語が維持される
  it 'keeps the selected language after OAuth login (existing user)' do
    login_as(user, scope: :user)
    visit edit_user_registration_path(locale: 'ja')
    expect(page).to have_current_path(edit_user_registration_path(locale: 'ja'), ignore_query: true)
    # expect(page).to have_content('アカウント設定') # ←日本語文言で確認するなら
    find('[data-testid="account-link-github"]').click
    expect(page).to have_current_path(edit_user_registration_path(locale: 'ja'), ignore_query: true)
    # expect(page).to have_content('アカウント設定')
  end

  # ログイン画面で言語を切り替えてからOAuthサインインした場合、同じ言語で表示される
  it 'keeps the selected language after OAuth login (from login screen)' do
    visit root_path(locale: 'en')
    find('.language-switcher').click_link('日本語')
    find('[data-testid="signin_with_github"]').click
    expect(page).to have_current_path(edit_user_registration_path(locale: 'ja'), ignore_query: true)
    # expect(page).to have_content('アカウント設定')
  end

  # 新規ユーザーが日本語でサインインした場合、同じ言語で表示される
  it 'keeps the selected language after OAuth registration (new user)' do
    new_user = create(:user, :confirmed)
    allow(User).to receive(:from_omniauth).and_return(new_user)
    allow(new_user).to receive(:persisted?).and_return(true)
    allow(new_user).to receive(:saved_change_to_id?).and_return(true)
    allow(new_user).to receive(:active_for_authentication?).and_return(true)
    visit root_path(locale: 'en')
    find('.language-switcher').click_link('日本語')
    find('[data-testid="signin_with_github"]').click
    expect(page).to have_current_path(edit_user_registration_path(locale: 'ja'), ignore_query: true)
    # expect(page).to have_content('アカウント設定')
  end
end
