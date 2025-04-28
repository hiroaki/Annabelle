require 'rails_helper'

RSpec.describe "Main Page", type: :system do
  before do
    driven_by(:cuprite_custom)
  end

  describe "Header Pane" do
    it "displays 'Log in' text" do
      visit root_path
      expect(page).to have_selector('h2', text: 'Log in')
    end
  end
end
