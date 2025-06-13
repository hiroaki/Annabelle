require 'rails_helper'

RSpec.describe LocaleService do
  let(:controller) { double('Controller') }
  let(:params) { {} }
  let(:request) { double('Request', env: {}) }
  let(:current_user) { nil }
  let(:service) { described_class.new(controller, current_user) }

  before do
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:request).and_return(request)
    
    # LocaleConfigurationから動的に設定を取得
    I18n.default_locale = LocaleConfiguration.default_locale
    allow(I18n).to receive(:available_locales).and_return(LocaleConfiguration.available_locales)
  end

  describe '#extract_from_user' do
    context 'when user has valid preferred_language' do
      let(:user) { double(preferred_language: 'ja') }

      it 'returns the user locale with source' do
        expect(service.extract_from_user(user)).to eq({ locale: 'ja', source: LocaleService::SOURCE_USER_PREFERENCE })
      end
    end

    context 'when user has invalid preferred_language' do
      let(:user) { double(preferred_language: 'invalid') }

      it 'returns nil values' do
        expect(service.extract_from_user(user)).to eq({ locale: nil, source: nil })
      end
    end

    context 'when user preferred_language is blank' do
      let(:user) { double(preferred_language: '') }

      it 'returns nil values' do
        expect(service.extract_from_user(user)).to eq({ locale: nil, source: nil })
      end
    end

    context 'when user is nil' do
      it 'returns nil values' do
        expect(service.extract_from_user(nil)).to eq({ locale: nil, source: nil })
      end
    end
  end

  describe '#extract_from_header' do
    context 'with valid accept language header' do
      it 'extracts ja from Japanese header with source' do
        header = 'ja,en-US;q=0.9,en;q=0.8'
        expect(service.extract_from_header(header)).to eq({ locale: 'ja', source: LocaleService::SOURCE_BROWSER_HEADER })
      end

      it 'extracts en from English header with source' do
        header = 'en-US,en;q=0.9'
        expect(service.extract_from_header(header)).to eq({ locale: 'en', source: LocaleService::SOURCE_BROWSER_HEADER })
      end
    end

    context 'with invalid accept language header' do
      it 'returns nil values for completely unsupported locales' do
        header = 'fr,de,zh-CN'
        expect(service.extract_from_header(header)).to eq({ locale: nil, source: nil })
      end

      it 'returns supported locale with source even when unsupported ones are present' do
        header = 'fr,en-US;q=0.9,en;q=0.8'
        expect(service.extract_from_header(header)).to eq({ locale: 'en', source: LocaleService::SOURCE_BROWSER_HEADER })
      end

      it 'respects quality values and returns highest priority supported locale with source' do
        header = 'fr;q=0.9,ja;q=0.8,en;q=0.7'
        expect(service.extract_from_header(header)).to eq({ locale: 'ja', source: LocaleService::SOURCE_BROWSER_HEADER })
      end
    end

    context 'with blank header' do
      it 'returns nil values' do
        expect(service.extract_from_header('')).to eq({ locale: nil, source: nil })
        expect(service.extract_from_header(nil)).to eq({ locale: nil, source: nil })
      end
    end
  end

  describe '#redirect_path_for_user' do
    context 'when fallback locale is non-default' do
      it 'returns localized path' do
        allow(service).to receive(:determine_fallback_locale).and_return('ja')
        result = service.redirect_path_for_user(double)
        expect(result).to eq('/ja')
      end
    end

    context 'when fallback locale is default' do
      it 'returns :root_path symbol' do
        allow(service).to receive(:determine_fallback_locale).and_return('en')
        result = service.redirect_path_for_user(double)
        expect(result).to eq(:root_path)
      end
    end

    context 'with specific fallback scenarios' do
      it 'uses user preference through fallback for Japanese user' do
        user = double(preferred_language: 'ja')
        # userがcurrent_userとして設定される前提で、extract_from_userが動作することを確認
        allow(service).to receive(:current_user).and_return(user)
        result = service.redirect_path_for_user(user)
        expect(result).to eq('/ja')
      end
    end
  end

  describe '#determine_effective_locale' do
    context 'with explicit locale argument' do
      it 'returns the provided locale if valid' do
        expect(service.determine_effective_locale('ja')).to eq('ja')
      end

      it 'ignores invalid locale and falls back' do
        allow(service).to receive(:determine_fallback_locale).and_return(LocaleConfiguration.default_locale.to_s)
        expect(service.determine_effective_locale('invalid')).to eq(LocaleConfiguration.default_locale.to_s)
      end
    end

    context 'with URL locale parameter' do
      let(:params) { { locale: 'ja' } }

      it 'returns locale parameter if valid' do
        expect(service.determine_effective_locale).to eq('ja')
      end
    end

    context 'with invalid URL locale parameter' do
      let(:params) { { locale: 'invalid' } }

      it 'falls back when URL locale is invalid' do
        allow(service).to receive(:determine_fallback_locale).and_return('en')
        expect(service.determine_effective_locale).to eq('en')
      end
    end

    context 'fallback scenarios' do
      let(:params) { {} }  # URLパラメータなし

      it 'uses fallback locale when no URL locale provided' do
        allow(service).to receive(:determine_fallback_locale).and_return('ja')
        expect(service.determine_effective_locale).to eq('ja')
      end
    end
  end

  describe '#determine_fallback_locale' do
    context 'with user preference' do
      let(:current_user) { double(preferred_language: 'ja') }

      it 'returns user preference if valid' do
        expect(service.determine_fallback_locale).to eq('ja')
      end
    end

    context 'with browser header' do
      let(:request) { double(env: { 'HTTP_ACCEPT_LANGUAGE' => 'ja,en-US;q=0.9,en;q=0.8' }) }

      it 'returns header locale if valid and no user preference' do
        expect(service.determine_fallback_locale).to eq('ja')
      end
    end

    context 'with no preferences' do
      it 'returns default locale' do
        expect(service.determine_fallback_locale).to eq(LocaleConfiguration.default_locale.to_s)
      end
    end
  end

  describe '#set_locale' do
    it 'sets I18n.locale to determined locale' do
      expect(I18n).to receive(:locale=).with('ja')
      service.set_locale('ja')
    end
  end

  describe '#current_path_with_locale' do
    let(:request) { double(path: '/messages', query_string: 'page=2') }

    it 'delegates to LocaleHelper.current_path_with_locale' do
      expect(LocaleHelper).to receive(:current_path_with_locale).with(request, 'ja')
      service.current_path_with_locale('ja')
    end
  end

  describe '#redirect_path_with_user_locale' do
    before do
      allow(controller).to receive(:root_path).and_return('/root')
    end

    context 'when fallback locale is non-default' do
      it 'returns the localized path' do
        allow(service).to receive(:determine_fallback_locale).and_return('ja')
        expect(service.redirect_path_with_user_locale(double)).to eq('/ja')
      end
    end

    context 'when fallback locale is default' do
      it 'returns controller.root_path' do
        allow(service).to receive(:determine_fallback_locale).and_return('en')
        expect(service.redirect_path_with_user_locale(double)).to eq('/root')
      end
    end
  end

  describe '#determine_post_login_redirect_path' do
    let(:resource) { double }
    
    before do
      allow(controller).to receive(:stored_location_for).with(resource).and_return(stored_location)
      allow(controller).to receive(:root_path).and_return('/root')
    end

    context 'when no stored location' do
      let(:stored_location) { nil }

      it 'returns redirect_path_with_user_locale result' do
        allow(service).to receive(:determine_fallback_locale).and_return('ja')
        expect(service.determine_post_login_redirect_path(resource)).to eq('/ja')
      end
    end

    context 'when stored location is locale-only path' do
      let(:stored_location) { '/ja' }

      it 'returns redirect_path_with_user_locale result' do
        allow(service).to receive(:determine_fallback_locale).and_return('ja')
        expect(service.determine_post_login_redirect_path(resource)).to eq('/ja')
      end
    end

    context 'when stored location is regular path' do
      let(:stored_location) { '/messages' }

      it 'returns the stored location' do
        expect(service.determine_post_login_redirect_path(resource)).to eq('/messages')
      end
    end
  end
end
