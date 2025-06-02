require 'rails_helper'

RSpec.describe 'Messages Form', type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  before do
    @original_value = Devise.allow_unconfirmed_access_for
    Devise.allow_unconfirmed_access_for = 7.days
  end

  after do
    Devise.allow_unconfirmed_access_for = @original_value
  end

  let(:confirmed_user) { create(:user, :confirmed) }
  let(:unconfirmed_user) { create(:user, :unconfirmed) }

  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  context 'when the user is not confirmed' do
    before do
      login_as unconfirmed_user
      visit messages_path
    end

    it 'disables the form' do
      expect(page).to have_selector('fieldset[disabled]', visible: true)
      expect(page).to have_content(I18n.t('messages.email_confirmation_required'))
    end

    it 'disables the comment field' do
      expect(page).to have_field('comment', disabled: true)
    end
  end

  context 'when the user is confirmed' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'enables the form' do
      expect(page).not_to have_selector('fieldset[disabled]')
      expect(page).not_to have_content(I18n.t('messages.email_confirmation_required'))
    end

    it 'enables the comment field' do
      expect(page).to have_field('comment', disabled: false)
    end

    it 'allows form submission' do
      fill_in 'comment', with: 'This is a test message'
      click_button I18n.t('messages.form.post')
      expect(page).to have_content('This is a test message')
    end
  end
end
