# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remember me機能', type: :system do
  let(:user) { create(:user, :confirmed) }

  it 'Remember meにチェックを入れてログインすると、ブラウザを閉じても自動的にログインされること' do
    # 1回目のログイン - Remember meにチェックを入れる
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    check 'Remember me'
    click_button I18n.t('devise.sessions.log_in')

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))

    # ブラウザセッションをリセットすると remember のための cookie も削除してしまうため使えません。
    # Capybara.reset_session!
    # 代わりに cookie を自前でやりくりします。 selenium と cuprite とではやり方が異なります。

    # remember_user_token クッキーを取得
    remember_cookie = page.driver.cookies['remember_user_token']

    # セッション（session cookie）を削除（remember cookie は保持）
    page.driver.cookies.each do |name, cookie|
      page.driver.remove_cookie(name) unless name == 'remember_user_token'
    end

    # すべてのクッキーをクリアし、remember cookie だけ再設定
    page.driver.cookies.clear
    if remember_cookie
      page.driver.set_cookie(
        'remember_user_token',
        remember_cookie.value,
        domain: remember_cookie.domain,
        path: remember_cookie.path,
        expires: remember_cookie.expires
      )
    end

    # 再度サイトを訪問（新しいブラウザで開く操作に相当）
    visit root_path
    expect(page).to have_selector("[data-testid='current-user-display']")
  end

  it 'Remember meにチェックを入れずにログインすると、ブラウザを閉じるとログアウトされること' do
    # ログイン - Remember meにチェックを入れない
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button I18n.t('devise.sessions.log_in')

    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))

    # remember_user_token クッキーを取得
    remember_cookie = page.driver.cookies['remember_user_token']

    # セッション（session cookie）を削除（remember cookie は保持）
    page.driver.cookies.each do |name, cookie|
      page.driver.remove_cookie(name) unless name == 'remember_user_token'
    end

    # すべてのクッキーをクリアし、remember cookie だけ再設定
    page.driver.cookies.clear
    if remember_cookie
      page.driver.set_cookie(
        'remember_user_token',
        remember_cookie.value,
        domain: remember_cookie.domain,
        path: remember_cookie.path,
        expires: remember_cookie.expires
      )
    end

    visit root_path
    expect(page).not_to have_selector("[data-testid='current-user-display']")
  end
end
