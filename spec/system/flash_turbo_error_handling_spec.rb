# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Flash Message System - Turbo Error Handling', type: :system do
  before do
    @original_value = Devise.allow_unconfirmed_access_for
    Devise.allow_unconfirmed_access_for = 7.days
  end

  after do
    Devise.allow_unconfirmed_access_for = @original_value
  end

  let(:confirmed_user) { create(:user, :confirmed) }

  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  describe 'HTTP error status handling' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    context 'when simulating HTTP 413 (Request Entity Too Large)' do
      it 'shows appropriate error message for file size errors' do
        # Simulate a 413 error by creating a mock event
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:render', {
            detail: {
              fetchResponse: { status: 413 }
            }
          });
          document.dispatchEvent(event);
        JS
        
        expect(page).to have_selector('[data-testid="flash-message"]', text: 'ファイルサイズが大きすぎます（413エラー）', wait: 2)
        
        # Check that it's displayed as an alert
        flash_element = page.find('[data-testid="flash-message"]')
        expect(flash_element['class']).to include('text-red-700', 'bg-red-100')
      end
    end

    context 'when simulating HTTP 503 (Service Unavailable)' do
      it 'shows appropriate error message for service unavailable' do
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:render', {
            detail: {
              fetchResponse: { status: 503 }
            }
          });
          document.dispatchEvent(event);
        JS
        
        expect(page).to have_selector('[data-testid="flash-message"]', text: 'サービスが一時的に利用できません（503エラー）', wait: 2)
      end
    end

    context 'when simulating other 4xx errors' do
      it 'shows generic 4xx error message for 400' do
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:render', {
            detail: {
              fetchResponse: { status: 400 }
            }
          });
          document.dispatchEvent(event);
        JS
        
        expect(page).to have_selector('[data-testid="flash-message"]', text: 'リクエストに問題があります（4xxエラー）', wait: 2)
      end

      it 'shows generic 4xx error message for 422' do
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:render', {
            detail: {
              fetchResponse: { status: 422 }
            }
          });
          document.dispatchEvent(event);
        JS
        
        expect(page).to have_selector('[data-testid="flash-message"]', text: 'リクエストに問題があります（4xxエラー）', wait: 2)
      end
    end

    context 'when simulating 5xx errors' do
      it 'shows generic server error message for 500' do
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:render', {
            detail: {
              fetchResponse: { status: 500 }
            }
          });
          document.dispatchEvent(event);
        JS
        
        expect(page).to have_selector('[data-testid="flash-message"]', text: 'サーバーエラーが発生しました（5xxエラー）', wait: 2)
      end
    end

    context 'when simulating network errors' do
      it 'shows network error message for fetch request errors' do
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:fetch-request-error', {
            detail: {
              error: new Error('Network error')
            }
          });
          document.dispatchEvent(event);
        JS
        
        expect(page).to have_selector('[data-testid="flash-message"]', text: 'ネットワークエラーが発生しました', wait: 2)
      end
    end

    context 'when there are existing server-side flash messages' do
      it 'does not show client-side error messages when server flash exists' do
        # First add a server-side message to storage
        page.execute_script(<<~JS)
          const storage = document.getElementById('flash-storage');
          const ul = storage.querySelector('ul');
          const li = document.createElement('li');
          li.dataset.type = 'notice';
          li.textContent = 'Server-side message';
          ul.appendChild(li);
        JS
        
        # Now trigger a client-side error
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:render', {
            detail: {
              fetchResponse: { status: 413 }
            }
          });
          document.dispatchEvent(event);
        JS
        
        # Should not show the 413 error message due to competition avoidance
        expect(page).not_to have_selector('[data-testid="flash-message"]', text: 'ファイルサイズが大きすぎます（413エラー）')
        
        # Render the server message to verify it exists
        page.execute_script('renderFlashMessages()')
        expect(page).to have_selector('[data-testid="flash-message"]', text: 'Server-side message')
      end
    end
  end

  describe 'Turbo events integration' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'properly listens for turbo:render events' do
      # Verify the event listener is attached by checking if it responds to events
      initial_count = page.evaluate_script('document.querySelectorAll("[data-testid=flash-message]").length')
      
      page.execute_script(<<~JS)
        const event = new CustomEvent('turbo:render', {
          detail: {
            fetchResponse: { status: 413 }
          }
        });
        document.dispatchEvent(event);
      JS
      
      expect(page).to have_selector('[data-testid="flash-message"]', wait: 2)
      new_count = page.evaluate_script('document.querySelectorAll("[data-testid=flash-message]").length')
      expect(new_count).to be > initial_count
    end

    it 'properly listens for turbo:fetch-request-error events' do
      initial_count = page.evaluate_script('document.querySelectorAll("[data-testid=flash-message]").length')
      
      page.execute_script(<<~JS)
        const event = new CustomEvent('turbo:fetch-request-error', {
          detail: {
            error: new Error('Network error')
          }
        });
        document.dispatchEvent(event);
      JS
      
      expect(page).to have_selector('[data-testid="flash-message"]', wait: 2)
      new_count = page.evaluate_script('document.querySelectorAll("[data-testid=flash-message]").length')
      expect(new_count).to be > initial_count
    end
  end

  describe 'Edge cases and error handling' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'handles events with missing detail information gracefully' do
      # Should not crash when event detail is missing
      expect {
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:render', {
            detail: {}
          });
          document.dispatchEvent(event);
        JS
      }.not_to raise_error
      
      # Should not show any error messages
      expect(page).not_to have_selector('[data-testid="flash-message"]')
    end

    it 'handles events with null fetchResponse gracefully' do
      expect {
        page.execute_script(<<~JS)
          const event = new CustomEvent('turbo:render', {
            detail: {
              fetchResponse: null
            }
          });
          document.dispatchEvent(event);
        JS
      }.not_to raise_error
      
      expect(page).not_to have_selector('[data-testid="flash-message"]')
    end

    it 'handles successful status codes appropriately' do
      # Should not show error messages for 2xx status codes
      page.execute_script(<<~JS)
        const event = new CustomEvent('turbo:render', {
          detail: {
            fetchResponse: { status: 200 }
          }
        });
        document.dispatchEvent(event);
      JS
      
      expect(page).not_to have_selector('[data-testid="flash-message"]')
      
      page.execute_script(<<~JS)
        const event = new CustomEvent('turbo:render', {
          detail: {
            fetchResponse: { status: 302 }
          }
        });
        document.dispatchEvent(event);
      JS
      
      expect(page).not_to have_selector('[data-testid="flash-message"]')
    end
  end
end