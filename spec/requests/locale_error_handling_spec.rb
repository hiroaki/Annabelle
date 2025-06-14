require 'rails_helper'

RSpec.describe 'Locale error handling', type: :request do
  context 'when invalid locale is given in params' do
    it 'does not redirect or show flash, just logs the error' do
      allow(I18n).to receive(:locale=).and_raise(I18n::InvalidLocale.new('xx'))
      get '/en' # any valid path, will trigger set_locale
      # 画面遷移やflashは発生しない
      expect(response).not_to be_redirect
      expect(flash[:alert]).to be_nil
    end
  end
end
