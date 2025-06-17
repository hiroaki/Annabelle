# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'One-person mode (auto login)', type: :system do
  before do
    @original_enabled = Rails.configuration.x.auto_login.enabled
    @original_email = Rails.configuration.x.auto_login.email
    Rails.configuration.x.auto_login.enabled = true
    Rails.configuration.x.auto_login.email = 'auto@example.com'
    @user = User.find_by(email: 'auto@example.com') || create(:user, :confirmed, email: 'auto@example.com', password: 'password123')
  end

  after do
    Rails.configuration.x.auto_login.enabled = @original_enabled
    Rails.configuration.x.auto_login.email = @original_email
  end

  it 'auto logs in and allows posting and viewing a message' do
    visit messages_path
    fill_in 'comment', with: 'one person mode message'
    click_button I18n.t('messages.form.post')
    message = Message.order(:created_at).last
    expect(page).to have_selector("[data-testid='message-content-#{message.id}']", text: 'one person mode message')
  end
end
