require 'rails_helper'

RSpec.describe LocaleHelper do
  before do
    I18n.default_locale = LocaleConfiguration.default_locale
    allow(I18n).to receive(:available_locales).and_return(LocaleConfiguration.available_locales)
  end

  describe '.current_path_with_locale' do
    it 'generates path-based locale URL for non-default locale' do
      result = LocaleHelper.current_path_with_locale('/messages', 'ja')
      expect(result).to eq('/ja/messages')
    end

    it 'generates default locale URL with prefix' do
      result = LocaleHelper.current_path_with_locale('/messages', 'en')
      expect(result).to eq('/en/messages')
    end

    it 'handles path with existing locale prefix' do
      result = LocaleHelper.current_path_with_locale('/ja/messages', 'en')
      expect(result).to eq('/en/messages')
    end

    it 'handles root path correctly' do
      result = LocaleHelper.current_path_with_locale('/', 'ja')
      expect(result).to eq('/ja')
    end

    it 'handles root path for default locale' do
      result = LocaleHelper.current_path_with_locale('/', 'en')
      expect(result).to eq('/en')
    end
  end

  describe '.remove_locale_prefix' do
    it 'removes locale prefix from path' do
      expect(LocaleHelper.remove_locale_prefix('/ja/messages')).to eq('/messages')
      expect(LocaleHelper.remove_locale_prefix('/en/users')).to eq('/users')
    end

    it 'handles locale-only path' do
      expect(LocaleHelper.remove_locale_prefix('/ja')).to eq('/')
      expect(LocaleHelper.remove_locale_prefix('/en')).to eq('/')
    end

    it 'handles path without locale prefix' do
      expect(LocaleHelper.remove_locale_prefix('/messages')).to eq('/messages')
      expect(LocaleHelper.remove_locale_prefix('/')).to eq('/')
    end

    it 'handles blank or nil path' do
      expect(LocaleHelper.remove_locale_prefix('')).to eq('/')
      expect(LocaleHelper.remove_locale_prefix(nil)).to eq('/')
    end
  end

  describe '.add_locale_prefix' do
    it 'adds locale prefix to path' do
      expect(LocaleHelper.add_locale_prefix('/messages', 'ja')).to eq('/ja/messages')
    end

    it 'handles root path' do
      expect(LocaleHelper.add_locale_prefix('/', 'ja')).to eq('/ja')
    end

    it 'adds default locale prefix (explicit locale required)' do
      expect(LocaleHelper.add_locale_prefix('/messages', 'en')).to eq('/en/messages')
    end
  end

  describe '.skip_locale_redirect?' do
    it 'returns true for skip paths' do
      expect(LocaleHelper.skip_locale_redirect?('/up')).to be true
      expect(LocaleHelper.skip_locale_redirect?('/locale/ja')).to be true
      expect(LocaleHelper.skip_locale_redirect?('/users/auth/github')).to be true
    end

    it 'returns false for normal paths' do
      expect(LocaleHelper.skip_locale_redirect?('/messages')).to be false
      expect(LocaleHelper.skip_locale_redirect?('/users/sign_in')).to be false
    end
  end

  describe '.prepare_oauth_locale_params' do
    let(:session) { {} }
    let(:current_time) { Time.current }

    before do
      allow(Time).to receive(:current).and_return(current_time)
      allow(I18n).to receive(:locale).and_return(:en)
      allow(I18n).to receive(:default_locale).and_return(:en)
    end

    context 'with locale parameter' do
      it 'includes lang parameter for non-default locale' do
        params = { locale: 'ja' }
        result = LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(result[:lang]).to eq('ja')
        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end

      it 'omits lang parameter for default locale' do
        params = { locale: 'en' }
        result = LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(result[:lang]).to be_nil
        expect(session[:oauth_locale]).to eq('en')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end

      it 'validates locale before including and falls back to I18n.locale' do
        params = { locale: 'invalid' }
        result = LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(result[:lang]).to be_nil
        expect(session[:oauth_locale]).to eq('en') # falls back to I18n.locale
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
    end

    context 'with lang parameter (backward compatibility)' do
      it 'uses lang parameter when locale is not present' do
        params = { lang: 'ja' }
        result = LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(result[:lang]).to eq('ja')
        expect(session[:oauth_locale]).to eq('en') # falls back to I18n.locale
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end

      it 'prioritizes locale over lang parameter' do
        params = { locale: 'ja', lang: 'fr' }
        result = LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(result[:lang]).to eq('ja')
        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end

      it 'validates lang parameter' do
        params = { lang: 'invalid' }
        result = LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(result[:lang]).to be_nil
        expect(session[:oauth_locale]).to eq('en') # falls back to I18n.locale
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
    end

    context 'without locale parameters' do
      it 'uses current I18n locale for session storage' do
        allow(I18n).to receive(:locale).and_return(:ja)
        params = {}
        result = LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(result[:lang]).to eq('ja')
        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end

      it 'omits lang parameter when current locale is default' do
        allow(I18n).to receive(:locale).and_return(:en)
        params = {}
        result = LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(result[:lang]).to be_nil
        expect(session[:oauth_locale]).to eq('en')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
    end

    context 'session handling' do
      it 'stores valid locale in session with timestamp' do
        params = { locale: 'ja' }
        LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end

      it 'stores fallback locale when invalid locale provided' do
        params = { locale: 'invalid' }
        LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(session[:oauth_locale]).to eq('en') # falls back to I18n.locale
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end

      it 'stores fallback locale when no valid parameter provided' do
        allow(I18n).to receive(:locale).and_return(:ja)
        params = { locale: 'invalid' }
        LocaleHelper.prepare_oauth_locale_params(params, session)

        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
    end
  end
end
