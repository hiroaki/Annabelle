require 'rails_helper'

RSpec.describe LocaleHelper do
  include LocaleHelper
  before do
    I18n.default_locale = LocaleConfiguration.default_locale
    allow(I18n).to receive(:available_locales).and_return(LocaleConfiguration.available_locales)
  end

  describe '#current_path_with_locale' do
    it 'generates locale-prefixed URL for non-default locale' do
      result = current_path_with_locale('/messages', 'ja')
      expect(result).to eq('/ja/messages')
    end
    it 'generates locale-prefixed URL for default locale' do
      result = current_path_with_locale('/messages', 'en')
      expect(result).to eq('/en/messages')
    end
    it 'replaces existing locale prefix' do
      result = current_path_with_locale('/ja/messages', 'en')
      expect(result).to eq('/en/messages')
    end
    it 'handles root path for non-default locale' do
      result = current_path_with_locale('/', 'ja')
      expect(result).to eq('/ja')
    end
    it 'handles root path for default locale' do
      result = current_path_with_locale('/', 'en')
      expect(result).to eq('/en')
    end
  end

  describe '#remove_locale_prefix' do
    it 'removes locale prefix from path' do
      expect(remove_locale_prefix('/ja/messages')).to eq('/messages')
      expect(remove_locale_prefix('/en/users')).to eq('/users')
    end
    it 'returns root for locale-only path' do
      expect(remove_locale_prefix('/ja')).to eq('/')
      expect(remove_locale_prefix('/en')).to eq('/')
    end
    it 'returns path unchanged if no locale prefix' do
      expect(remove_locale_prefix('/messages')).to eq('/messages')
      expect(remove_locale_prefix('/')).to eq('/')
    end
    it 'returns root for blank or nil path' do
      expect(remove_locale_prefix('')).to eq('/')
      expect(remove_locale_prefix(nil)).to eq('/')
    end
    it 'raises error for path with double slashes' do
      expect { remove_locale_prefix('//ja/messages') }.to raise_error(ArgumentError, /Invalid path format/)
      expect { remove_locale_prefix('/foo//bar') }.to raise_error(ArgumentError, /Invalid path format/)
    end
    it 'raises error for path with control characters or spaces' do
      expect { remove_locale_prefix("/foo\nbar") }.to raise_error(ArgumentError, /Invalid path format/)
      expect { remove_locale_prefix('/foo bar') }.to raise_error(ArgumentError, /Invalid path format/)
    end
    it 'raises error for path with .. traversal' do
      expect { remove_locale_prefix('/foo/../bar') }.to raise_error(ArgumentError, /Invalid path format/)
      expect { remove_locale_prefix('/../bar') }.to raise_error(ArgumentError, /Invalid path format/)
    end
    it 'raises error for path not starting with slash' do
      expect { remove_locale_prefix('foo/bar') }.to raise_error(ArgumentError, /Invalid path format/)
      expect { remove_locale_prefix('') }.not_to raise_error # 空文字は許容
      expect { remove_locale_prefix(nil) }.not_to raise_error # nilは許容
    end
  end

  describe '#add_locale_prefix' do
    it 'adds locale prefix to path' do
      expect(add_locale_prefix('/messages', 'ja')).to eq('/ja/messages')
      expect(add_locale_prefix('/users', 'en')).to eq('/en/users')
    end
    it 'handles root path' do
      expect(add_locale_prefix('/', 'ja')).to eq('/ja')
      expect(add_locale_prefix('/', 'en')).to eq('/en')
    end
    it 'handles blank path' do
      expect(add_locale_prefix('', 'ja')).to eq('/ja')
      expect(add_locale_prefix(nil, 'ja')).to eq('/ja')
    end
    it 'replaces existing locale prefix' do
      expect(add_locale_prefix('/en/messages', 'ja')).to eq('/ja/messages')
      expect(add_locale_prefix('/ja/users', 'en')).to eq('/en/users')
    end
    it 'handles paths with query parameters' do
      expect(add_locale_prefix('/messages?page=1', 'ja')).to eq('/ja/messages?page=1')
    end
    it 'handles paths with fragments' do
      expect(add_locale_prefix('/messages#section1', 'ja')).to eq('/ja/messages#section1')
    end
  end

  describe '#localized_path_for' do
    before do
      allow(Rails.application.routes.url_helpers).to receive(:edit_profile_path).and_return('/profile/edit')
      allow(Rails.application.routes.url_helpers).to receive(:edit_profile_path).with(locale: 'ja').and_return('/ja/profile/edit')
    end
    it 'generates locale-prefixed path for non-default locale' do
      result = localized_path_for(:edit_profile_path, 'ja')
      expect(result).to eq('/ja/profile/edit')
    end
    it 'generates locale-prefixed path for default locale' do
      allow(Rails.application.routes.url_helpers).to receive(:edit_profile_path).with(locale: 'en').and_return('/en/profile/edit')
      result = localized_path_for(:edit_profile_path, 'en')
      expect(result).to eq('/en/profile/edit')
    end
  end

  describe '#base_link_classes' do
    before do
      allow(I18n).to receive(:locale).and_return(:ja)
    end
    it 'returns classes with font-bold for current locale' do
      result = base_link_classes(:ja)
      expect(result).to include('font-bold')
      expect(result).to include('hover:text-slate-600')
    end
    it 'returns classes without font-bold for non-current locale' do
      result = base_link_classes(:en)
      expect(result).not_to include('font-bold')
      expect(result).to include('hover:text-slate-600')
    end
    it 'includes additional classes when provided' do
      result = base_link_classes(:ja, 'custom-class')
      expect(result).to include('custom-class')
    end
  end

  describe '#prepare_oauth_locale_params' do
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
        result = prepare_oauth_locale_params(params, session)
        expect(result[:lang]).to eq('ja')
        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
      it 'omits lang parameter for default locale' do
        params = { locale: 'en' }
        result = prepare_oauth_locale_params(params, session)
        expect(result[:lang]).to be_nil
        expect(session[:oauth_locale]).to eq('en')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
      it 'validates locale before including and falls back to I18n.locale' do
        params = { locale: 'invalid' }
        result = prepare_oauth_locale_params(params, session)
        expect(result[:lang]).to be_nil
        expect(session[:oauth_locale]).to eq('en')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
    end
    context 'with lang parameter (backward compatibility)' do
      it 'uses lang parameter when locale is not present' do
        params = { lang: 'ja' }
        result = prepare_oauth_locale_params(params, session)
        expect(result[:lang]).to eq('ja')
        expect(session[:oauth_locale]).to eq('en')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
      it 'prioritizes locale over lang parameter' do
        params = { locale: 'ja', lang: 'fr' }
        result = prepare_oauth_locale_params(params, session)
        expect(result[:lang]).to eq('ja')
        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
      it 'validates lang parameter' do
        params = { lang: 'invalid' }
        result = prepare_oauth_locale_params(params, session)
        expect(result[:lang]).to be_nil
        expect(session[:oauth_locale]).to eq('en')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
    end
    context 'without locale parameters' do
      it 'uses current I18n locale for session storage' do
        allow(I18n).to receive(:locale).and_return(:ja)
        params = {}
        result = prepare_oauth_locale_params(params, session)
        expect(result[:lang]).to eq('ja')
        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
      it 'omits lang parameter when current locale is default' do
        allow(I18n).to receive(:locale).and_return(:en)
        params = {}
        result = prepare_oauth_locale_params(params, session)
        expect(result[:lang]).to be_nil
        expect(session[:oauth_locale]).to eq('en')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
    end
    context 'session handling' do
      it 'stores valid locale in session with timestamp' do
        params = { locale: 'ja' }
        prepare_oauth_locale_params(params, session)
        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
      it 'stores fallback locale when invalid locale provided' do
        params = { locale: 'invalid' }
        prepare_oauth_locale_params(params, session)
        expect(session[:oauth_locale]).to eq('en')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
      it 'stores fallback locale when no valid parameter provided' do
        allow(I18n).to receive(:locale).and_return(:ja)
        params = { locale: 'invalid' }
        prepare_oauth_locale_params(params, session)
        expect(session[:oauth_locale]).to eq('ja')
        expect(session[:oauth_locale_timestamp]).to eq(current_time.to_i)
      end
    end
  end
end
