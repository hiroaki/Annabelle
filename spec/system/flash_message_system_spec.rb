# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Flash Message System Integration', type: :system do
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

  describe 'Flash storage structure' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'has the flash-storage container in the page' do
      expect(page).to have_selector('#flash-storage', visible: false)
    end

    it 'has an empty ul element inside flash-storage by default' do
      storage = page.find('#flash-storage', visible: false)
      expect(storage).to have_selector('ul', visible: false)
      # The ul should be empty initially
      expect(page.evaluate_script('document.querySelector("#flash-storage ul").children.length')).to eq(0)
    end

    it 'has the flash-message-container for displaying messages' do
      expect(page).to have_selector('#flash-message-container')
    end
  end

  describe 'Server-side flash message rendering' do
    context 'when there are server-side flash messages' do
      it 'renders flash messages with proper styling and attributes' do
        # Trigger a server-side flash message by trying to delete another user's message
        other_user = create(:user, :confirmed)
        message = create(:message, user: other_user, content: "other message")

        login_as confirmed_user
        visit messages_path

        accept_confirm do
          delete_link = find_link("delete-message-#{message.id}", visible: :all)
          page.execute_script("arguments[0].click();", delete_link)
        end

        # Check that the flash message is properly displayed
        expect(page).to have_selector('[data-testid="flash-message"]', text: I18n.t('messages.errors.not_owned'), wait: 2)

        # Verify the flash message has proper styling and attributes
        flash_element = page.find('[data-testid="flash-message"]')
        expect(flash_element['role']).to eq('alert')
        expect(flash_element['data-controller']).to eq('dismissable')
        expect(flash_element['class']).to include('text-red-700', 'bg-red-100')
      end

      it 'clears the flash-storage after rendering messages' do
        other_user = create(:user, :confirmed)
        message = create(:message, user: other_user, content: "other message")

        login_as confirmed_user
        visit messages_path

        accept_confirm do
          delete_link = find_link("delete-message-#{message.id}", visible: :all)
          page.execute_script("arguments[0].click();", delete_link)
        end

        # Wait for the flash message to appear
        expect(page).to have_selector('[data-testid="flash-message"]', wait: 2)

        # Check that flash-storage ul is empty after rendering
        expect(page.evaluate_script('document.querySelector("#flash-storage ul").children.length')).to eq(0)
      end
    end

    context 'when posting a message successfully' do
      it 'does not show any flash messages for successful posts' do
        login_as confirmed_user
        visit messages_path

        fill_in 'comment', with: 'This is a test message'
        click_button I18n.t('messages.form.post')

        # Successful post should not show flash messages
        expect(page).not_to have_selector('[data-testid="flash-message"]')
        expect(page).to have_content('This is a test message')
      end
    end
  end

  describe 'Turbo Stream flash message updates' do
    it 'properly updates flash messages via Turbo Stream responses' do
      login_as confirmed_user

      # Simulate a condition that would trigger a flash message via turbo stream
      # This would happen when the server responds with a turbo stream that includes flash messages
      other_user = create(:user, :confirmed)
      message = create(:message, user: other_user, content: "message to delete")

      visit messages_path

      accept_confirm do
        delete_link = find_link("delete-message-#{message.id}", visible: :all)
        page.execute_script("arguments[0].click();", delete_link)
      end

      # The turbo stream should update flash-storage and render the message
      expect(page).to have_selector('[data-testid="flash-message"]', text: I18n.t('messages.errors.not_owned'), wait: 2)
    end
  end

  describe 'Client-side error handling' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    context 'when JavaScript functions are available' do
      it 'has the renderFlashMessages function available globally' do
        expect(page.evaluate_script('typeof window.renderFlashMessages')).to eq('function')
      end

      it 'has the addFlashMessageToStorage function available globally' do
        expect(page.evaluate_script('typeof window.addFlashMessageToStorage')).to eq('function')
      end
    end

    context 'when adding client-side flash messages' do
      it 'can add and render alert messages' do
        # Add a client-side alert message
        page.execute_script('addFlashMessageToStorage("Test alert message", "alert")')
        page.execute_script('renderFlashMessages()')

        # Check that the message is displayed
        expect(page).to have_selector('[data-testid="flash-message"]', text: 'Test alert message')

        # Check styling for alert type
        flash_element = page.find('[data-testid="flash-message"]')
        expect(flash_element['class']).to include('text-red-700', 'bg-red-100')
      end

      it 'can add and render notice messages' do
        page.execute_script('addFlashMessageToStorage("Test notice message", "notice")')
        page.execute_script('renderFlashMessages()')

        expect(page).to have_selector('[data-testid="flash-message"]', text: 'Test notice message')

        # Check styling for notice type
        flash_element = page.find('[data-testid="flash-message"]')
        expect(flash_element['class']).to include('text-blue-700', 'bg-blue-100')
      end

      it 'can add and render warning messages' do
        page.execute_script('addFlashMessageToStorage("Test warning message", "warning")')
        page.execute_script('renderFlashMessages()')

        expect(page).to have_selector('[data-testid="flash-message"]', text: 'Test warning message')

        # Check styling for warning type
        flash_element = page.find('[data-testid="flash-message"]')
        expect(flash_element['class']).to include('text-yellow-700', 'bg-yellow-100')
      end

      it 'clears flash-storage after rendering client-side messages' do
        page.execute_script('addFlashMessageToStorage("Test message", "alert")')

        # Verify message is in storage
        storage_count = page.evaluate_script('document.querySelector("#flash-storage ul").children.length')
        expect(storage_count).to eq(1)

        page.execute_script('renderFlashMessages()')

        # Verify storage is cleared after rendering
        storage_count_after = page.evaluate_script('document.querySelector("#flash-storage ul").children.length')
        expect(storage_count_after).to eq(0)
      end

      it 'correctly adds multiple messages to storage' do
        # Test that storage works correctly before testing rendering
        page.execute_script('addFlashMessageToStorage("First message", "alert")')
        expect(page.evaluate_script('document.querySelector("#flash-storage ul").children.length')).to eq(1)

        page.execute_script('addFlashMessageToStorage("Second message", "notice")')
        expect(page.evaluate_script('document.querySelector("#flash-storage ul").children.length')).to eq(2)

        page.execute_script('addFlashMessageToStorage("Third message", "warning")')
        expect(page.evaluate_script('document.querySelector("#flash-storage ul").children.length')).to eq(3)

        # Check the actual content
        messages = page.evaluate_script(<<~JS)
          Array.from(document.querySelectorAll("#flash-storage ul li")).map(li => ({
            type: li.dataset.type,
            text: li.textContent
          }))
        JS

        expect(messages).to eq([
          { 'type' => 'alert', 'text' => 'First message' },
          { 'type' => 'notice', 'text' => 'Second message' },
          { 'type' => 'warning', 'text' => 'Third message' }
        ])
      end

      it 'can render multiple messages at once without dismissable controller' do
        page.execute_script('addFlashMessageToStorage("First message", "alert")')
        page.execute_script('addFlashMessageToStorage("Second message", "notice")')
        page.execute_script('addFlashMessageToStorage("Third message", "warning")')

        # Test the storage first
        storage_count = page.evaluate_script('document.querySelector("#flash-storage ul").children.length')
        expect(storage_count).to eq(3)

        # Temporarily disable dismissable controller to test basic rendering
        page.execute_script(<<~JS)
          // Temporarily override createElement to avoid dismissable controller
          const originalCreateElement = document.createElement;
          document.createElement = function(tag) {
            const element = originalCreateElement.call(document, tag);
            if (tag === "div") {
              // Don't set data-controller for this test
              const originalSetAttribute = element.setAttribute;
              element.setAttribute = function(name, value) {
                if (name !== "data-controller") {
                  originalSetAttribute.call(element, name, value);
                }
              };
            }
            return element;
          };

          renderFlashMessages();

          // Restore original
          document.createElement = originalCreateElement;
        JS

        # Check that all messages appear
        expect(page).to have_selector('[data-testid="flash-message"]', count: 3)
        expect(page).to have_content('First message')
        expect(page).to have_content('Second message')
        expect(page).to have_content('Third message')
      end

      it 'renders multiple messages correctly and clears storage' do
        # Add messages and verify each step
        page.execute_script('addFlashMessageToStorage("First message", "alert")')
        page.execute_script('addFlashMessageToStorage("Second message", "notice")')
        page.execute_script('addFlashMessageToStorage("Third message", "warning")')

        # Verify storage has all messages
        storage_count = page.evaluate_script('document.querySelector("#flash-storage ul").children.length')
        expect(storage_count).to eq(3)

        # Call renderFlashMessages and immediately check results
        page.execute_script('renderFlashMessages()')

        # Check that messages are properly rendered
        expect(page).to have_selector('[data-testid="flash-message"]', count: 3)

        # Storage should be cleared after rendering
        storage_count_after = page.evaluate_script('document.querySelector("#flash-storage ul").children.length')
        expect(storage_count_after).to eq(0)
      end

      it 'can render multiple messages at once' do
        page.execute_script('addFlashMessageToStorage("First message", "alert")')
        page.execute_script('addFlashMessageToStorage("Second message", "notice")')
        page.execute_script('addFlashMessageToStorage("Third message", "warning")')
        page.execute_script('renderFlashMessages()')

        # Verify all messages are displayed
        expect(page).to have_selector('[data-testid="flash-message"]', count: 3)
        expect(page).to have_content('First message')
        expect(page).to have_content('Second message')
        expect(page).to have_content('Third message')

        # Verify different message types are properly styled
        alert_element = page.find('[data-testid="flash-message"]', text: 'First message')
        notice_element = page.find('[data-testid="flash-message"]', text: 'Second message')
        warning_element = page.find('[data-testid="flash-message"]', text: 'Third message')

        expect(alert_element['class']).to include('text-red-700', 'bg-red-100')
        expect(notice_element['class']).to include('text-blue-700', 'bg-blue-100')
        expect(warning_element['class']).to include('text-yellow-700', 'bg-yellow-100')
      end
    end
  end

  describe 'Dismissable functionality integration' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'adds dismissable controller to rendered flash messages' do
      page.execute_script('addFlashMessageToStorage("Dismissable test message", "alert")')
      page.execute_script('renderFlashMessages()')

      flash_element = page.find('[data-testid="flash-message"]')
      expect(flash_element['data-controller']).to eq('dismissable')
    end

    it 'allows flash messages to be dismissed when clicking the close button' do
      page.execute_script('addFlashMessageToStorage("Message to dismiss", "alert")')
      page.execute_script('renderFlashMessages()')

      # Wait for the dismissable controller to add the close button
      expect(page).to have_selector('[data-testid="flash-message"]', text: 'Message to dismiss')
      sleep(0.5) # Give time for the dismissable controller to add the close button

      # The dismissable controller should add a close button
      flash_element = page.find('[data-testid="flash-message"]')
      close_button = flash_element.find('button', text: '×')

      # Click the close button
      close_button.click

      # The message should be dismissed (removed from DOM after animation)
      expect(page).not_to have_selector('[data-testid="flash-message"]', text: 'Message to dismiss', wait: 2)
    end
  end

  describe 'Accessibility features' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'includes proper ARIA attributes for screen readers' do
      page.execute_script('addFlashMessageToStorage("Accessible message", "alert")')
      page.execute_script('renderFlashMessages()')

      flash_element = page.find('[data-testid="flash-message"]')
      expect(flash_element['role']).to eq('alert')
    end

    it 'maintains compatibility with assistive technologies' do
      # Add multiple types of messages to test different alert levels
      page.execute_script('addFlashMessageToStorage("Error message", "alert")')
      page.execute_script('addFlashMessageToStorage("Info message", "notice")')
      page.execute_script('addFlashMessageToStorage("Warning message", "warning")')
      page.execute_script('renderFlashMessages()')

      # All should have alert role for accessibility
      flash_elements = page.all('[data-testid="flash-message"]')
      expect(flash_elements.count).to eq(3)
      flash_elements.each do |element|
        expect(element['role']).to eq('alert')
      end
    end
  end

  describe 'Competition avoidance between server and client messages' do
    it 'prioritizes server-side flash messages over client-side error messages' do
      # Create a scenario where both server and client would try to show messages
      other_user = create(:user, :confirmed)
      message = create(:message, user: other_user, content: "message causing server flash")

      login_as confirmed_user
      visit messages_path

      # Manually add a client-side message to storage first
      page.execute_script('addFlashMessageToStorage("Client error message", "alert")')

      # Now trigger a server action that would also create a flash message
      accept_confirm do
        delete_link = find_link("delete-message-#{message.id}", visible: :all)
        page.execute_script("arguments[0].click();", delete_link)
      end

      # Should show the server message, not the client message
      expect(page).to have_selector('[data-testid="flash-message"]', text: I18n.t('messages.errors.not_owned'), wait: 2)
      expect(page).not_to have_content('Client error message')
    end
  end

  describe 'Error message content and formatting' do
    before do
      login_as confirmed_user
      visit messages_path
    end

    it 'preserves message text content correctly' do
      test_message = 'Test message with special characters: áéíóú & < > " \''
      page.execute_script("addFlashMessageToStorage(#{test_message.to_json}, 'alert')")
      page.execute_script('renderFlashMessages()')

      expect(page).to have_selector('[data-testid="flash-message"]', text: test_message)
    end

    it 'handles empty messages gracefully' do
      page.execute_script('addFlashMessageToStorage("", "alert")')
      page.execute_script('renderFlashMessages()')

      # Should not create a flash message for empty content
      expect(page).not_to have_selector('[data-testid="flash-message"]')
    end
  end
end