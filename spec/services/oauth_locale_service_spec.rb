require 'rails_helper'

describe OAuthLocaleService do
  let(:controller_mock) do
    instance_double('ApplicationController').tap do |controller|
      allow(controller).to receive(:params).and_return({})
      allow(controller).to receive(:request).and_return(request_mock)
      allow(controller).to receive(:session).and_return(session_mock)
    end
  end
  let(:request_mock) { instance_double('ActionDispatch::Request', env: request_env) }
  let(:request_env) { {} }
  let(:session_mock) { {} }
  let(:user) { nil }
  let(:service) { described_class.new(controller_mock, user) }

  describe '#determine_oauth_locale' do
    subject { service.determine_oauth_locale }

    it 'returns locale from omniauth.params if valid' do
      allow(request_mock).to receive(:env).and_return({ 'omniauth.params' => { 'lang' => 'ja' } })
      allow(LocaleValidator).to receive(:valid_locale?).and_call_original
      allow(LocaleValidator).to receive(:valid_locale?).with('ja').and_return(true)
      expect(service.determine_oauth_locale).to eq('ja')
    end

    it 'returns default locale if session locale is not available' do
      allow(request_mock).to receive(:env).and_return({})
      session_mock.clear
      session_mock['oauth_locale'] = 'de'
      session_mock['oauth_locale_timestamp'] = Time.current.to_i
      allow(LocaleValidator).to receive(:valid_locale?).and_call_original
      allow(LocaleValidator).to receive(:valid_locale?).with('de').and_return(false)
      allow(I18n).to receive(:default_locale).and_return(:en)
      expect(service.determine_oauth_locale).to eq('en')
    end

    it 'returns user preferred_language if omniauth.params and session are invalid' do
      allow(request_mock).to receive(:env).and_return({})
      allow(LocaleValidator).to receive(:valid_locale?).and_call_original
      allow(LocaleValidator).to receive(:valid_locale?).with('de').and_return(false)
      user2 = double(preferred_language: 'es')
      allow(LocaleValidator).to receive(:valid_locale?).with('es').and_return(false)
      allow(I18n).to receive(:default_locale).and_return(:en)
      service2 = described_class.new(controller_mock, user2)
      expect(service2.determine_oauth_locale).to eq('en')
    end

    it 'returns default locale if header locale is not available' do
      allow(request_mock).to receive(:env).and_return({ 'HTTP_ACCEPT_LANGUAGE' => 'it,en' })
      allow(LocaleValidator).to receive(:valid_locale?).and_call_original
      allow(LocaleValidator).to receive(:valid_locale?).with('it').and_return(false)
      allow(LocaleValidator).to receive(:valid_locale?).with('en').and_return(false)
      allow(LocaleValidator).to receive(:valid_locale?).with('invalid').and_return(false)
      allow(LocaleValidator).to receive(:valid_locale?).with(nil).and_return(false)
      user2 = double(preferred_language: 'invalid')
      allow(I18n).to receive(:default_locale).and_return(:en)
      service2 = described_class.new(controller_mock, user2)
      expect(service2.determine_oauth_locale).to eq('en')
    end

    it 'returns default locale if nothing matches' do
      allow(request_mock).to receive(:env).and_return({ 'HTTP_ACCEPT_LANGUAGE' => 'fr,de' })
      allow(LocaleValidator).to receive(:valid_locale?).and_call_original
      allow(LocaleValidator).to receive(:valid_locale?).with('fr').and_return(false)
      allow(LocaleValidator).to receive(:valid_locale?).with('de').and_return(false)
      allow(LocaleValidator).to receive(:valid_locale?).with('invalid').and_return(false)
      allow(LocaleValidator).to receive(:valid_locale?).with(nil).and_return(false)
      user2 = double(preferred_language: 'invalid')
      allow(I18n).to receive(:default_locale).and_return(:en)
      service2 = described_class.new(controller_mock, user2)
      expect(service2.determine_oauth_locale).to eq('en')
    end
  end
end
