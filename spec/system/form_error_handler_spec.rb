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

    it "has server-side translated error messages in data attributes" do
      form = page.find('form[action*="messages"]')
      expect(form['data-form-error-handler-error-413-value']).to be_present
      expect(form['data-form-error-handler-error-502-value']).to be_present
      expect(form['data-form-error-handler-error-503-value']).to be_present
      expect(form['data-form-error-handler-error-504-value']).to be_present
      expect(form['data-form-error-handler-error-network-value']).to be_present
    end

    it "uses the correct locale in translated error messages" do
      form = page.find('form[action*="messages"]')
      # In English locale, should contain English text
      expect(form['data-form-error-handler-error-413-value']).to include('too large')
    end
  end

  describe "HTML language attribute" do
    it "sets the lang attribute on the HTML element" do
      expect(page.find('html')['lang']).to eq(I18n.locale.to_s)
    end
  end

  # Note: Testing actual JavaScript error handling requires a full browser environment
  # with Stimulus loaded. The core logic is tested in our Node.js test file.
  # In a real testing environment, we would mock HTTP responses with status codes
  # like 413, 502, etc., and verify the error messages appear using the server-side translations.
end