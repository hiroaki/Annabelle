# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Message form textarea', type: :system, js: true do
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

  it 'keeps full rows on mobile during interaction' do
    resize_to(:mobile)
    visit messages_path

    expect(page).to have_selector('#comment', visible: true)
    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)

    find('#comment').click
    expect(page).to have_selector("#comment[rows='3']", visible: true)

    find('#message_strip_metadata', visible: :all).click
    expect(page).to have_selector("#comment[rows='3']", visible: true)

    find('body').click(0, 0)
    expect(page).to have_selector("#comment[rows='3']", visible: true)
  end

  it 'keeps full rows on desktop as well' do
    resize_to(:desktop)
    visit messages_path

    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)

    find('#comment').click
    expect(page).to have_selector("#comment[rows='3']", visible: true)

    find('body').click
    expect(page).to have_selector("#comment[rows='3']", visible: true)
  end

  it 'keeps full rows when resizing between desktop and mobile' do
    resize_to(:desktop)
    visit messages_path
    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)

    resize_to(:mobile)
    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)

    resize_to(:desktop)
    expect(page).to have_selector("#comment[rows='3']", visible: true, wait: 2)
  end
end
