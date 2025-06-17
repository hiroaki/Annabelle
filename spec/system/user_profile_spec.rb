# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ユーザープロファイル編集', type: :system do
  let(:user) { create(:user, :confirmed, username: 'testuser', preferred_language: 'en') }

  before do
    login_as(user)
  end

  describe 'プロファイル編集ページ' do
    it 'プロファイル編集ページにアクセスできること' do
      visit edit_user_path(user)
      
      expect(page).to have_content('Profile')
      expect(page).to have_field('Username', with: 'testuser')
      expect(page).to have_select('Display Language', selected: 'English')
    end
  end

  describe 'ユーザー名の変更' do
    it '有効なユーザー名で更新できること' do
      visit edit_user_path(user)
      
      fill_in 'Username', with: 'newusername'
      click_button 'Update'
      
      expect(page).to have_content('Your profile has been updated successfully')
      expect(page).to have_field('Username', with: 'newusername')
      expect(user.reload.username).to eq('newusername')
    end

    it '無効なユーザー名では更新できないこと' do
      visit edit_user_path(user)
      
      fill_in 'Username', with: ''
      click_button 'Update'
      
      expect(page).to have_content("Username can't be blank")
      expect(user.reload.username).to eq('testuser')
    end
  end

  describe '言語設定の変更' do
    context '言語を日本語に変更する場合' do
      it '日本語URLにリダイレクトされること' do
        visit edit_user_path(user)
        
        select '日本語', from: 'Display Language'
        click_button 'Update'
        
        # 日本語URLにリダイレクトされることを確認
        expect(page).to have_current_path("/ja/users/#{user.id}/edit")
        expect(page).to have_content('プロフィールを更新しました')
        expect(page).to have_content('プロフィール')
        expect(user.reload.preferred_language).to eq('ja')
      end
    end

    context '言語を英語に変更する場合' do
      before do
        user.update(preferred_language: 'ja')
      end

      it '英語URLにリダイレクトされること' do
        visit "/ja/users/#{user.id}/edit"
        
        select 'English', from: '表示言語'
        click_button '更新'
        
        # 英語URLにリダイレクトされることを確認（テスト環境では/en/プレフィックス付き）
        expect(page).to have_current_path("/en/users/#{user.id}/edit")
        expect(page).to have_content('Your profile has been updated successfully')
        expect(page).to have_content('Profile')
        expect(user.reload.preferred_language).to eq('en')
      end
    end

    context 'ブラウザ言語設定を使用する場合' do
      it '空文字選択時はブラウザ言語に基づいてリダイレクトされること' do
        # Cupriteでのheader設定
        page.driver.headers = { 'Accept-Language' => 'ja,en-US;q=0.9,en;q=0.8' }
        visit edit_user_path(user)
        
        select 'Use browser language', from: 'Display Language'
        click_button 'Update'
        
        # ブラウザ言語（日本語）に基づいて日本語URLにリダイレクト
        expect(page).to have_current_path("/ja/users/#{user.id}/edit")
        expect(user.reload.preferred_language).to eq('')
      end
    end

    context '同じ言語を再選択する場合' do
      it 'リダイレクトせずに編集ページに留まること' do
        visit edit_user_path(user)
        
        select 'English', from: 'Display Language'
        click_button 'Update'
        
        # テスト環境では英語URLに/en/プレフィックスが付く
        expect(page).to have_current_path("/en/users/#{user.id}/edit")
        expect(page).to have_content('Your profile has been updated successfully')
        expect(user.reload.preferred_language).to eq('en')
      end
    end
  end

  describe 'ユーザー名と言語設定の同時変更' do
    it 'ユーザー名と言語を同時に変更できること' do
      visit edit_user_path(user)
      
      fill_in 'Username', with: 'newusername'
      select '日本語', from: 'Display Language'
      click_button 'Update'
      
      # 日本語URLにリダイレクトされ、両方の変更が適用されること
      expect(page).to have_current_path("/ja/users/#{user.id}/edit")
      expect(page).to have_content('プロフィールを更新しました')
      
      user.reload
      expect(user.username).to eq('newusername')
      expect(user.preferred_language).to eq('ja')
    end
  end

  describe 'URL直接アクセス' do
    it '日本語URLで直接アクセスできること' do
      visit "/ja/users/#{user.id}/edit"
      
      expect(page).to have_content('プロフィール')
      expect(page).to have_field('ユーザー名', with: 'testuser')
    end

    it '英語URLで直接アクセスできること' do
      visit "/en/users/#{user.id}/edit"
      
      expect(page).to have_content('Profile')
      expect(page).to have_field('Username', with: 'testuser')
    end
  end

  describe 'バリデーションエラー' do
    it 'サポートされていない言語を選択した場合エラーが表示されること' do
      visit edit_user_path(user)
      
      # 直接無効な値を送信（通常のUIではできないが、悪意のあるリクエストをシミュレート）
      page.execute_script("document.querySelector('select[name=\"user[preferred_language]\"]').innerHTML += '<option value=\"invalid\">Invalid</option>';")
      select 'Invalid', from: 'Display Language'
      click_button 'Update'
      
      expect(page).to have_content('Display Language is not a valid locale')
      expect(user.reload.preferred_language).to eq('en') # 変更されない
    end
  end
end
