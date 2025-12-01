require 'rails_helper'

RSpec.describe 'TwoFactorSettings Availability', type: :system do
  let(:user) { FactoryBot.create(:user) }

  before do
    login_as user, scope: :user
  end

  context 'when 2FA is unavailable (ENV vars missing)' do
    it 'redirects to dashboard with an alert message when accessing 2FA settings' do
      with_env('ENABLE_2FA' => nil) do
        visit new_two_factor_settings_path

        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content(I18n.t('two_factor_settings.unavailable'))
      end
    end
  end
end
