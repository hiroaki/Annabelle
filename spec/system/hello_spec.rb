# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Main Page", type: :system do
  describe "Header Pane" do
    it "displays 'Log in' text" do
      visit root_path
      expect(page).to have_selector('h2', text: 'Log in')
    end
  end
end
