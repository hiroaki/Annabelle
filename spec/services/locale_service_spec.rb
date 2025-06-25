require 'rails_helper'

describe LocaleService do
  before do
    I18n.default_locale = LocaleConfiguration.default_locale
    allow(I18n).to receive(:available_locales).and_return(LocaleConfiguration.available_locales)
  end

  describe '.determine_locale' do
    let(:request) { double(env: { 'HTTP_ACCEPT_LANGUAGE' => 'ja,en' }) }
    let(:user) { double(preferred_language: 'ja') }

    it 'returns the param locale if valid' do
      params = { locale: 'ja' }
      expect(LocaleService.determine_locale(params, request, user)).to eq('ja')
    end

    it 'returns user preferred_language if param is invalid' do
      params = { locale: 'invalid' }
      expect(LocaleService.determine_locale(params, request, user)).to eq('ja')
    end

    it 'returns header locale if param and user are invalid' do
      params = { locale: 'invalid' }
      user2 = double(preferred_language: 'invalid')
      expect(LocaleService.determine_locale(params, request, user2)).to eq('ja')
    end

    it 'returns default locale if nothing matches' do
      params = { locale: 'invalid' }
      user2 = double(preferred_language: 'invalid')
      req = double(env: { 'HTTP_ACCEPT_LANGUAGE' => 'fr,de' })
      expect(LocaleService.determine_locale(params, req, user2)).to eq(LocaleConfiguration.default_locale.to_s)
    end
  end

  describe '.valid_locale?' do
    it 'returns true for supported locale' do
      expect(LocaleService.valid_locale?('ja')).to be true
    end
    it 'returns false for unsupported locale' do
      expect(LocaleService.valid_locale?('fr')).to be false
    end
  end
end
