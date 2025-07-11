require 'rails_helper'

RSpec.describe "Form Error Handler", type: :system do
  let(:user) { create(:user, :confirmed) }

  before do
    sign_in user
    visit root_path
  end

  describe "error message container" do
    it "has the flash message container for error display" do
      expect(page).to have_selector('#flash-message-container')
    end

    it "loads the form with error handler controller" do
      form = page.find('form[action*="messages"]')
      expect(form['data-controller']).to include('form-error-handler')
    end
  end

  # Note: Testing actual JavaScript error handling requires a full browser environment
  # with Stimulus loaded. The core logic is tested in our Node.js test file.
  # In a real testing environment, we would mock HTTP responses with status codes
  # like 413, 502, etc., and verify the error messages appear.
end