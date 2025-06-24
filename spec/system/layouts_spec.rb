require 'rails_helper'

RSpec.describe 'Configuration menu layout', type: :system do
  let(:user) { FactoryBot.create(:user) }

  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  before do
    login_as(user)
  end

  it 'shows configuration menu for registrations controller' do
    visit edit_user_registration_path
    expect(page).to have_selector('[data-testid="configuration-menu"]')
  end

  it 'shows configuration menu for users controller (dashboard)' do
    visit dashboard_path
    expect(page).to have_selector('[data-testid="configuration-menu"]')
  end

  it 'shows configuration menu for two_factor_settings controller' do
    visit new_two_factor_settings_path
    expect(page).to have_selector('[data-testid="configuration-menu"]')
  end

  it 'does not show configuration menu for messages controller' do
    visit messages_path
    expect(page).not_to have_selector('[data-testid="configuration-menu"]')
  end
end
