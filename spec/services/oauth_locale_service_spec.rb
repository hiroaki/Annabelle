require 'rails_helper'

RSpec.describe OAuthLocaleService do
  let(:controller_mock) do
    instance_double('ApplicationController').tap do |controller|
      allow(controller).to receive(:params).and_return({})
      allow(controller).to receive(:request).and_return(request_mock)
      allow(controller).to receive(:session).and_return(session_mock)
    end
  end

  let(:request_mock) do
    instance_double('ActionDispatch::Request').tap do |request|
      allow(request).to receive(:env).and_return(request_env)
    end
  end

  let(:request_env) { {} }
  let(:session_mock) { {} }
  let(:user) { nil }
  let(:service) { described_class.new(controller_mock, user) }

  describe '#determine_oauth_locale' do
    subject { service.determine_oauth_locale }

    context 'when omniauth.params contains lang parameter' do
      let(:request_env) { { 'omniauth.params' => { 'lang' => 'ja' } } }

      before do
        allow(LocaleValidator).to receive(:valid_locale?).with('ja').and_return(true)
      end

      it 'returns locale from omniauth params' do
        expect(subject).to eq({ locale: 'ja', source: LocaleService::SOURCE_OMNIAUTH_PARAMS })
      end
    end

    context 'when omniauth.params contains locale parameter' do
      let(:request_env) { { 'omniauth.params' => { 'locale' => 'fr' } } }

      before do
        allow(LocaleValidator).to receive(:valid_locale?).with('fr').and_return(true)
      end

      it 'returns locale from omniauth params' do
        expect(subject).to eq({ locale: 'fr', source: LocaleService::SOURCE_OMNIAUTH_PARAMS })
      end
    end

    context 'when session has oauth_locale information' do
      let(:session_mock) do
        {
          oauth_locale: 'de',
          oauth_locale_timestamp: Time.current.to_i - 100 # 100秒前
        }
      end

      before do
        allow(LocaleValidator).to receive(:valid_locale?).with('de').and_return(true)
      end

      it 'returns locale from session' do
        expect(subject).to eq({ locale: 'de', source: LocaleService::SOURCE_SESSION })
      end

      it 'deletes session data after use' do
        subject
        expect(session_mock).to be_empty
      end
    end

    context 'when session data is expired' do
      let(:session_mock) do
        {
          oauth_locale: 'de',
          oauth_locale_timestamp: Time.current.to_i - 1000 # 有効期限切れ
        }
      end

      context 'when user prefers a language' do
        let(:user) { instance_double('User', preferred_language: 'es') }

        before do
          allow(LocaleValidator).to receive(:valid_locale?).with('es').and_return(true)
          allow(service).to receive(:extract_from_header).and_return({ locale: nil, source: nil })
          # extract_from_userメソッドをモック
          allow(service).to receive(:extract_from_user).with(user).and_return({ locale: 'es', source: LocaleService::SOURCE_USER_PREFERENCE })
        end

        it 'returns locale from user preference' do
          expect(subject).to eq({ locale: 'es', source: LocaleService::SOURCE_USER_PREFERENCE })
        end
      end
    end

    context 'when HTTP_ACCEPT_LANGUAGE header is present' do
      let(:request_env) { { 'HTTP_ACCEPT_LANGUAGE' => 'it,en;q=0.9' } }

      before do
        # extract_from_headerメソッドをモック
        allow(service).to receive(:extract_from_header).with('it,en;q=0.9').and_return({ locale: 'it', source: LocaleService::SOURCE_BROWSER_HEADER })
        allow(LocaleValidator).to receive(:valid_locale?).with('it').and_return(true)
      end

      it 'returns locale from header' do
        expect(subject).to eq({ locale: 'it', source: LocaleService::SOURCE_BROWSER_HEADER })
      end
    end

    context 'when no locale information is available' do
      before do
        allow(I18n).to receive(:default_locale).and_return(:en)
      end

      it 'returns default locale' do
        expect(subject).to eq({ locale: 'en', source: LocaleService::SOURCE_DEFAULT })
      end
    end
  end

  describe '#restore_oauth_locale_from_session' do
    subject { service.restore_oauth_locale_from_session }

    context 'when no timestamp in session' do
      let(:session_mock) { {} }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when timestamp is valid and locale is present' do
      let(:current_time) { Time.current }
      let(:session_mock) do
        {
          oauth_locale: 'ja',
          oauth_locale_timestamp: current_time.to_i - 500
        }
      end

      it 'returns the locale information' do
        expect(subject).to eq({ locale: 'ja' })
      end

      it 'clears the session' do
        subject
        expect(session_mock).to be_empty
      end
    end

    context 'when timestamp is a string in session' do
      let(:current_time) { Time.current }
      let(:session_mock) do
        {
          oauth_locale: 'ja',
          oauth_locale_timestamp: (current_time.to_i - 500).to_s # 文字列として格納
        }
      end

      before do
        allow(LocaleValidator).to receive(:valid_locale?).with('ja').and_return(true)
      end

      it 'correctly converts to integer and returns the locale information' do
        expect(subject).to eq({ locale: 'ja' })
      end

      it 'clears the session' do
        subject
        expect(session_mock).to be_empty
      end
    end

    context 'when timestamp is expired' do
      let(:session_mock) do
        {
          oauth_locale: 'ja',
          oauth_locale_timestamp: Time.current.to_i - OAuthLocaleService::OAUTH_LOCALE_SESSION_TTL - 10
        }
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end

      it 'clears the session' do
        subject
        expect(session_mock).to be_empty
      end
    end

    context 'when locale is invalid' do
      let(:session_mock) do
        {
          oauth_locale: 'invalid-locale',
          oauth_locale_timestamp: Time.current.to_i - 100
        }
      end

      before do
        allow(LocaleValidator).to receive(:valid_locale?).with('invalid-locale').and_return(false)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#extract_from_omniauth_params' do
    subject { service.send(:extract_from_omniauth_params) }

    context 'with valid lang parameter' do
      let(:request_env) { { 'omniauth.params' => { 'lang' => 'ja' } } }

      it 'returns the lang parameter value' do
        expect(subject).to eq({ locale: 'ja', source: LocaleService::SOURCE_OMNIAUTH_PARAMS })
      end
    end

    context 'with invalid locale parameter' do
      let(:request_env) { { 'omniauth.params' => { 'locale' => 'invalid' } } }

      before do
        allow(LocaleValidator).to receive(:valid_locale?).with('invalid').and_return(false)
      end

      it 'returns nil locale' do
        expect(subject).to eq({ locale: nil, source: nil })
      end
    end
  end

  describe '#extract_from_session' do
    subject { service.send(:extract_from_session) }

    context 'when restore_oauth_locale_from_session returns a string' do
      before do
        allow(service).to receive(:restore_oauth_locale_from_session).and_return('ja')
      end

      it 'handles string values correctly' do
        expect(subject).to eq({ locale: 'ja', source: LocaleService::SOURCE_SESSION })
      end
    end

    context 'when restore_oauth_locale_from_session returns a hash' do
      before do
        allow(service).to receive(:restore_oauth_locale_from_session).and_return({ locale: 'fr' })
      end

      it 'handles hash values correctly' do
        expect(subject).to eq({ locale: 'fr', source: LocaleService::SOURCE_SESSION })
      end
    end

    context 'when restore_oauth_locale_from_session returns nil' do
      before do
        allow(service).to receive(:restore_oauth_locale_from_session).and_return(nil)
      end

      it 'returns nil locale' do
        expect(subject).to eq({ locale: nil, source: nil })
      end
    end

    context 'when restore_oauth_locale_from_session returns a hash with nil locale' do
      before do
        allow(service).to receive(:restore_oauth_locale_from_session).and_return({ locale: nil })
      end

      it 'returns nil locale and source' do
        expect(subject).to eq({ locale: nil, source: nil })
      end
    end
  end
end
