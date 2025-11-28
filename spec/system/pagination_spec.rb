# frozen_string_literal: true

require 'rails_helper'

# Tests for responsive pagination behavior on mobile and desktop viewports.
#
# This spec verifies:
# - Desktop displays full Kaminari pagination with page numbers
# - Mobile displays simplified prev/next buttons with direct page input
# - Window resizing triggers appropriate pagination display
# - Page input validation and navigation work correctly
#
# Run with: bundle exec rspec spec/system/pagination_spec.rb
# Run with visible browser: HEADLESS=0 bundle exec rspec spec/system/pagination_spec.rb
RSpec.describe 'Pagination', type: :system, js: true do
  let(:user) { create(:user, :confirmed) }

  before do
    # Create enough messages to trigger pagination
    create_list(:message, 30, user: user)

    login_as user
  end

  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  describe 'Desktop pagination (lg breakpoint and above)' do
    before do
      resize_to(:desktop)
      visit messages_path
    end

    it 'shows the full pagination with page numbers' do
      # Desktop should show the standard Kaminari pagination
      expect(page).to have_selector('nav[role="navigation"][aria-label="pager"]')
      expect(page).to have_selector('.page', visible: true) # Page number links
      # Check for prev/next using raw HTML entity or text content
      expect(page).to have_css('.prev', visible: true)
      expect(page).to have_css('.next', visible: true)
    end

    it 'hides the mobile pagination input' do
      # Mobile pagination should be hidden on desktop
      expect(page).not_to have_selector('input[type="number"][data-pagination-target="pageInput"]', visible: true)
    end

    it 'allows navigation via page number links' do
      # Use first pagination (top of page)
      within(first('nav[role="navigation"]')) do
        click_link '2'
      end

      expect(page).to have_current_path(/page=2/)
      expect(page).to have_selector('.current', text: '2')
    end
  end

  describe 'Mobile pagination (below lg breakpoint)' do
    before do
      resize_to(:mobile) # iPhone SE size
      visit messages_path
    end

    it 'shows the simplified mobile pagination' do
      # Mobile should show prev/next buttons and page input
      expect(page).to have_selector('nav[role="navigation"][aria-label="pager"]')
      expect(page).to have_selector('input[type="number"][data-pagination-target="pageInput"]', visible: true)
    end

    it 'hides the desktop pagination with page numbers' do
      # Desktop pagination should be hidden on mobile
      # Note: The page numbers might still be in DOM but not visible
      desktop_pagination = page.all('.page', visible: false)
      expect(desktop_pagination.any? { |el| el.visible? }).to be false
    end

    it 'allows navigation via prev/next buttons' do
      # Use first pagination (top of page)
      within(first('nav[role="navigation"]')) do
        # Find the next link within .next span
        within('.next') do
          click_link
        end
      end

      expect(page).to have_current_path(/page=2/)
    end

    it 'allows direct page navigation via input field' do
      # Navigate to page 3 using JavaScript to avoid element reference issues
      page.execute_script(<<~JS)
        const input = document.querySelector('input[data-pagination-target="pageInput"]');
        input.value = '3';
        input.dispatchEvent(new Event('change', { bubbles: true }));
      JS

      # Wait for navigation
      expect(page).to have_current_path(/page=3/, wait: 5)
    end

    it 'validates page number input' do
      current_page = page.execute_script(<<~JS)
        return parseInt(document.querySelector('input[data-pagination-target="pageInput"]').value);
      JS

      # Try invalid page number (too high) using JavaScript
      page.execute_script(<<~JS)
        const input = document.querySelector('input[data-pagination-target="pageInput"]');
        input.value = '999';
        input.dispatchEvent(new Event('change', { bubbles: true }));
      JS

      # Should reset to current page
      sleep 0.5 # Give time for validation

      new_value = page.execute_script(<<~JS)
        return parseInt(document.querySelector('input[data-pagination-target="pageInput"]').value);
      JS

      expect(new_value).to eq(current_page)
    end

    it 'displays current page and total pages' do
      within(first('nav[role="navigation"]')) do
        # Should show format like "1 / 3" (current / total)
        # Note: The text also includes HTML entities like &lsaquo; and &rsaquo;
        # which render as ‹ and ›, so we check for the numeric pattern
        text_content = page.text
        expect(text_content).to match(/\d+/)  # Has at least one number
        expect(text_content).to include('/')  # Has the separator
        total_pages = (Message.count.to_f / Kaminari.config.default_per_page).ceil
        expect(text_content).to include(total_pages.to_s)  # Has total pages
      end
    end

    it 'disables prev button on first page' do
      visit messages_path(page: 1)

      within(first('nav[role="navigation"]')) do
        prev_link = find('.prev')
        # Disabled prev should be a span, not a link
        expect(prev_link).to have_selector('span')
        expect(prev_link).not_to have_selector('a')
      end
    end

    it 'disables next button on last page' do
      last_page = (Message.count.to_f / Kaminari.config.default_per_page).ceil
      visit messages_path(page: last_page)

      within(first('nav[role="navigation"]')) do
        next_link = find('.next')
        # Disabled next should be a span, not a link
        expect(next_link).to have_selector('span')
        expect(next_link).not_to have_selector('a')
      end
    end
  end

  describe 'Responsive behavior on window resize' do
    it 'switches from desktop to mobile pagination' do
      # Start with desktop size
      resize_to(:desktop)
      visit messages_path

      # Should show desktop pagination
      expect(page).to have_selector('.page', visible: true)

      # Resize to mobile
      resize_to(:mobile)
      sleep 0.5 # Give CSS time to apply

      # Should now show mobile pagination
      expect(page).to have_selector('input[data-pagination-target="pageInput"]', visible: true)
      # Desktop page numbers should be hidden
      expect(page).not_to have_selector('.page', visible: true)
    end
  end
end
