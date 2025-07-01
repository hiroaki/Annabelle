# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User profile editing', type: :system do
  let(:user) { create(:user, :confirmed, username: 'testuser', preferred_language: 'en') }

  before do
    login_as(user)
  end

  describe 'Profile edit page' do
    it 'allows access to the profile edit page' do
      visit edit_profile_path

      expect(page).to have_content('Profile')
      expect(page).to have_field('Username', with: 'testuser')
      expect(page).to have_select('Display Language', selected: 'English')
    end
  end

  describe 'Username update' do
    it 'updates with a valid username' do
      visit edit_profile_path

      fill_in 'Username', with: 'newusername'
      click_button 'Update'

      expect(page).to have_content('Your profile has been updated successfully')
      expect(page).to have_field('Username', with: 'newusername')
      expect(user.reload.username).to eq('newusername')
    end

    it 'does not update with an invalid username' do
      visit edit_profile_path

      fill_in 'Username', with: ''
      click_button 'Update'

      expect(page).to have_content("Username can't be blank")
      expect(user.reload.username).to eq('testuser')
    end
  end

  describe 'Language setting change' do
    context 'when changing to Japanese' do
      it 'redirects to Japanese URL' do
        visit edit_profile_path

        select '日本語', from: 'Display Language'
        click_button 'Update'

        expect(page).to have_current_path('/ja/profile/edit')
        expect(page).to have_content('プロフィールを更新しました')
        expect(page).to have_content('プロフィール')
        expect(user.reload.preferred_language).to eq('ja')
      end
    end

    context 'when changing to English' do
      before do
        user.update(preferred_language: 'ja')
      end

      it 'redirects to English URL' do
        visit '/ja/profile/edit'

        select 'English', from: '表示言語'
        click_button '更新'

        expect(page).to have_current_path('/en/profile/edit')
        expect(page).to have_content('Your profile has been updated successfully')
        expect(page).to have_content('Profile')
        expect(user.reload.preferred_language).to eq('en')
      end
    end

    context 'when using browser language setting' do
      it 'redirects based on browser language when empty string is selected' do
        page.driver.headers = { 'Accept-Language' => 'ja,en-US;q=0.9,en;q=0.8' }
        visit edit_profile_path

        select 'Use browser language', from: 'Display Language'
        click_button 'Update'

        expect(page).to have_current_path('/ja/profile/edit')
        expect(user.reload.preferred_language).to eq('')
      end
    end

    context 'when re-selecting the same language' do
      it 'remains on the edit page without redirect' do
        visit edit_profile_path

        select 'English', from: 'Display Language'
        click_button 'Update'

        expect(page).to have_current_path('/en/profile/edit')
        expect(page).to have_content('Your profile has been updated successfully')
        expect(user.reload.preferred_language).to eq('en')
      end
    end
  end

  describe 'Simultaneous username and language change' do
    it 'updates both username and language' do
      visit edit_profile_path

      fill_in 'Username', with: 'newusername'
      select '日本語', from: 'Display Language'
      click_button 'Update'

      expect(page).to have_current_path('/ja/profile/edit')
      expect(page).to have_content('プロフィールを更新しました')

      user.reload
      expect(user.username).to eq('newusername')
      expect(user.preferred_language).to eq('ja')
    end
  end

  describe 'Direct URL access' do
    it 'allows direct access to Japanese URL' do
      visit '/ja/profile/edit'

      expect(page).to have_content('プロフィール')
      expect(page).to have_field('ユーザー名', with: 'testuser')
    end

    it 'allows direct access to English URL' do
      visit '/en/profile/edit'

      expect(page).to have_content('Profile')
      expect(page).to have_field('Username', with: 'testuser')
    end
  end

  describe 'Validation errors' do
    it 'shows error when selecting unsupported language' do
      visit edit_profile_path

      page.execute_script("document.querySelector('select[name=\"user[preferred_language]\"]').innerHTML += '<option value=\"invalid\">Invalid</option>';")
      select 'Invalid', from: 'Display Language'
      click_button 'Update'

      expect(page).to have_content('Display Language is not a valid locale')
      expect(user.reload.preferred_language).to eq('en')
    end
  end
end
