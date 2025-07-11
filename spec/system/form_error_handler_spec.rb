require 'rails_helper'

RSpec.describe "Form Error Handler", type: :system, js: true do
  let(:user) { create(:user, :confirmed) }

  before do
    sign_in user
    visit root_path
  end

  describe "client-side error handling" do
    it "displays error message for 413 status" do
      # Fill in a message
      fill_in 'content', with: 'Test message'
      
      # Mock a 413 response from the form submission
      page.execute_script(<<~JS)
        const form = document.querySelector('form[action="#{messages_path}"]');
        const event = new CustomEvent('turbo:submit-end', {
          detail: {
            success: false,
            response: { status: 413 }
          }
        });
        form.dispatchEvent(event);
      JS

      # Check that error message appears
      expect(page).to have_content('メッセージまたは添付ファイルのサイズが大きすぎます')
    end

    it "displays error message for 502 status" do
      # Fill in a message  
      fill_in 'content', with: 'Test message'
      
      # Mock a 502 response from the form submission
      page.execute_script(<<~JS)
        const form = document.querySelector('form[action="#{messages_path}"]');
        const event = new CustomEvent('turbo:submit-end', {
          detail: {
            success: false,
            response: { status: 502 }
          }
        });
        form.dispatchEvent(event);
      JS

      # Check that error message appears
      expect(page).to have_content('サーバーに一時的にアクセスできません')
    end
  end
end