# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ログアウト', type: :system do
  let(:user) { create(:user, :confirmed) }

  it 'ログアウトできること' do
    # ログイン
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button I18n.t('devise.sessions.log_in')

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))

    # ユーザーメニューを開いてログアウト
    # find("[data-testid='current-user-display']").click
    click_on 'current-user-signout'

    # ログアウト成功のメッセージを確認
    expect(page).to have_content(I18n.t('devise.sessions.signed_out'))
    # ログインボタンが表示されていることを確認
    expect(page).to have_content(I18n.t('devise.sessions.log_in'))
  end
end
