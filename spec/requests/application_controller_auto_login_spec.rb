require 'rails_helper'

RSpec.describe 'ApplicationController conditional_auto_login', type: :request do
  let!(:user) { create(:user, :confirmed, email: 'auto@example.com') }

  around do |example|
    original_enabled = Rails.configuration.x.auto_login.enabled
    original_email = Rails.configuration.x.auto_login.email
    Rails.configuration.x.auto_login.enabled = true
    Rails.configuration.x.auto_login.email = 'auto@example.com'
    example.run
    Rails.configuration.x.auto_login.enabled = original_enabled
    Rails.configuration.x.auto_login.email = original_email
  end

  it 'auto logs in as the configured user when not signed in' do
    get root_path
    expect(controller.current_user).to eq(user)
    expect(response).to have_http_status(:ok)
  end

  it 'does not auto login if already signed in' do
    sign_in user
    get root_path
    expect(controller.current_user).to eq(user)
    expect(response).to have_http_status(:ok)
  end

  it 'raises if the user is not active_for_authentication?' do
    user.update!(confirmed_at: nil)
    Rails.configuration.x.auto_login.email = user.email
    expect {
      get root_path
    }.to raise_error(RuntimeError, /conditional_auto_login failed/)
  end
end
