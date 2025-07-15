# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Proxy Error Handling', type: :system, js: true do
  let(:confirmed_user) { create(:user, :confirmed) }

  before do
    # Login as confirmed user
    visit new_user_session_path
    fill_in 'Email', with: confirmed_user.email
    fill_in 'Password', with: confirmed_user.password
    click_button 'Log in'
    visit messages_path
  end

  it 'shows error message for 413 Request Entity Too Large' do
    # This test simulates a 413 error by manually triggering the error handler
    # Since we can't easily mock actual HTTP responses in system tests,
    # we'll trigger the error handling directly via JavaScript
    
    page.execute_script("""
      // Simulate a 413 error event
      const errorEvent = new CustomEvent('turbo:fetch-request-error', {
        detail: {
          response: {
            status: 413,
            statusText: 'Request Entity Too Large'
          }
        }
      });
      document.dispatchEvent(errorEvent);
    """)
    
    # Check that the error message appears
    expect(page).to have_content('リクエストサイズが大きすぎます')
    expect(page).to have_css('.bg-red-100.border-red-400')
  end

  it 'does not show error message for other status codes' do
    # Test that we only handle 413 errors specifically
    page.execute_script("""
      const errorEvent = new CustomEvent('turbo:fetch-request-error', {
        detail: {
          response: {
            status: 500,
            statusText: 'Internal Server Error'
          }
        }
      });
      document.dispatchEvent(errorEvent);
    """)
    
    # Error message should not appear for non-413 errors
    expect(page).not_to have_content('リクエストサイズが大きすぎます')
  end

  it 'allows manual dismissal of error message' do
    # Show the error first
    page.execute_script("""
      const errorEvent = new CustomEvent('turbo:fetch-request-error', {
        detail: {
          response: {
            status: 413,
            statusText: 'Request Entity Too Large'
          }
        }
      });
      document.dispatchEvent(errorEvent);
    """)
    
    expect(page).to have_content('リクエストサイズが大きすぎます')
    
    # Click the dismiss button
    find('button', text: '×').click
    
    # Error message should be gone
    expect(page).not_to have_content('リクエストサイズが大きすぎます')
  end
end