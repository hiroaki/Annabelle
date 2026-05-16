# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Main Page", type: :system do
  describe "Header Pane" do
    it "displays 'Log in' text" do
      visit root_path
      expect(page).to have_selector('h2', text: 'Log in')
    end

    it 'does not show cable disconnected warning on login page reload' do
      # The login page intentionally has no Action Cable UI, so reloading it
      # should not surface a disconnect warning.
      visit new_user_session_path(locale: :ja)
      visit current_path

      expect(page).to have_selector('h2', text: 'ログイン')
      expect(page).to have_no_selector('[data-testid="flash-message"]', text: I18n.t('exports.cable_disconnected'), wait: 1)
    end
  end
end
