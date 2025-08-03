require 'rails_helper'

RSpec.describe 'GitHub OAuth UI', type: :system do
  shared_examples 'GitHub OAuth UI presence' do |should_have|
    it "#{should_have ? 'shows' : 'does not show'} GitHub login button on sign in page" do
      visit new_user_session_path
      if should_have
        expect(page).to have_button('Sign in with GitHub')
        expect(page).to have_selector(:link_or_button, 'Sign in with GitHub')
        expect(page).to have_selector('[data-testid="signin_with_github"]')
      else
        expect(page).not_to have_button('Sign in with GitHub')
        expect(page).not_to have_selector(:link_or_button, 'Sign in with GitHub')
        expect(page).not_to have_selector('[data-testid="signin_with_github"]')
      end
    end

    it "#{should_have ? 'shows' : 'does not show'} GitHub link button on account settings page" do
      user = FactoryBot.create(:user, :confirmed)
      login_as(user, scope: :user)
      visit edit_user_registration_path
      if should_have
        expect(page).to have_content(I18n.t('devise.omniauth_callbacks.provider.link', provider: 'GitHub')).or have_selector("[data-testid='account-link-github']")
      else
        expect(page).not_to have_content(I18n.t('devise.omniauth_callbacks.provider.link', provider: 'GitHub'))
        expect(page).not_to have_selector("[data-testid='account-link-github']")
        expect(page).not_to have_selector("[data-testid='account-unlink-github']")
      end
    end

    it "#{should_have ? 'shows' : 'does not show'} GitHub login button on OAuth locale sign in page" do
      visit new_user_session_path(locale: :ja)
      if should_have
        expect(page).to have_selector('[data-testid="signin_with_github"]')
      else
        expect(page).not_to have_selector('[data-testid="signin_with_github"]')
      end
    end
  end

  context 'when GitHub OAuth is enabled' do
    before do
      skip 'This spec is only for RSPEC_DISABLE_OAUTH_GITHUB not set' if ENV['RSPEC_DISABLE_OAUTH_GITHUB']
    end
    include_examples 'GitHub OAuth UI presence', true
  end

  context 'when GitHub OAuth is disabled' do
    before do
      skip 'This spec is only for RSPEC_DISABLE_OAUTH_GITHUB=1' unless ENV['RSPEC_DISABLE_OAUTH_GITHUB']
    end
    include_examples 'GitHub OAuth UI presence', false
  end
end
