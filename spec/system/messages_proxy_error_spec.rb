require 'rails_helper'

RSpec.describe 'Messages proxy error', type: :system do
  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  before do
    user = FactoryBot.create(:user, :confirmed)
    login_as(user)
  end

  it 'shows flash message when proxy returns 413 error' do
    visit messages_path
    fill_in 'comment', with: 'this is a test'

    # Cuprite (Ferrum) の network intercept で 413 エラーを返します
    page.driver.browser.network.intercept
    page.driver.browser.on(:request) do |request|
      if request.match?('/messages') && request.method == 'POST'
        request.respond(
          responseCode: 413,
          responseHeaders: { 'Content-Type' => 'text/plain' },
          body: 'Payload Too Large'
        )
      else
        request.continue
      end
    end

    click_button I18n.t('messages.form.post')

    # flash メッセージが表示されることを確認
    expect(page).to have_content(I18n.t('http_status_messages.413'))
  end
end
