# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rows Resizer', type: :system, js: true do
  let(:user) { create(:user, :confirmed) }

  before do
    login_as user
  end

  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  it 'starts compact on mobile and expands/collapses on focus/blur' do
    resize_to(:mobile)
    visit messages_path

    expect(page).to have_selector('#comment', visible: true)

    # Initially compact on mobile
    expect(page).to have_selector("#comment[rows='1']", visible: true, wait: 2)

    # Focus expands to initial rows (from textarea attribute)
    find('#comment').click
    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)

    # Blur collapses back to compact
    find('body').click
    expect(page).to have_selector("#comment[rows='1']", visible: true, wait: 2)
  end

  it 'always shows full rows on desktop regardless of focus' do
    resize_to(:desktop)
    visit messages_path

    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)

    find('#comment').click
    expect(page).to have_selector("#comment[rows='3']", visible: true)

    find('body').click
    expect(page).to have_selector("#comment[rows='3']", visible: true)
  end

  it 'adjusts rows when resizing between desktop and mobile' do
    resize_to(:desktop)
    visit messages_path
    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)

    resize_to(:mobile)
    expect(page).to have_selector("#comment[rows='1']", visible: true, wait: 2)

    find('#comment').click
    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)

    resize_to(:desktop)
    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)
  end
end
