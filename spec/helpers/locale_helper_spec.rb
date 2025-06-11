require 'rails_helper'

RSpec.describe LocaleHelper do
  before do
    I18n.default_locale = :en
    allow(I18n).to receive(:available_locales).and_return([:ja, :en])
  end

  describe '.extract_from_user' do
    context 'when user has valid preferred_language' do
      let(:user) { double(preferred_language: 'ja') }

      it 'returns the user locale' do
        expect(LocaleHelper.extract_from_user(user)).to eq('ja')
      end
    end

    context 'when user has invalid preferred_language' do
      let(:user) { double(preferred_language: 'invalid') }

      it 'returns nil' do
        expect(LocaleHelper.extract_from_user(user)).to be_nil
      end
    end

    context 'when user preferred_language is blank' do
      let(:user) { double(preferred_language: '') }

      it 'returns nil' do
        expect(LocaleHelper.extract_from_user(user)).to be_nil
      end
    end

    context 'when user is nil' do
      it 'returns nil' do
        expect(LocaleHelper.extract_from_user(nil)).to be_nil
      end
    end
  end

  describe '.extract_from_header' do
    context 'with valid accept language header' do
      it 'extracts ja from Japanese header' do
        header = 'ja,en-US;q=0.9,en;q=0.8'
        expect(LocaleHelper.extract_from_header(header)).to eq('ja')
      end

      it 'extracts en from English header' do
        header = 'en-US,en;q=0.9'
        expect(LocaleHelper.extract_from_header(header)).to eq('en')
      end
    end

    context 'with invalid accept language header' do
      it 'returns nil for unsupported locale' do
        header = 'fr,en-US;q=0.9,en;q=0.8'
        expect(LocaleHelper.extract_from_header(header)).to be_nil
      end
    end

    context 'with blank header' do
      it 'returns nil' do
        expect(LocaleHelper.extract_from_header('')).to be_nil
        expect(LocaleHelper.extract_from_header(nil)).to be_nil
      end
    end
  end

  describe '.current_path_with_locale' do
    let(:mock_request) { double(path: '/messages', query_string: 'page=2') }

    it 'adds lang parameter to URL' do
      result = LocaleHelper.current_path_with_locale(mock_request, 'ja')
      expect(result).to eq('/messages?lang=ja&page=2')
    end

    it 'replaces existing lang parameter' do
      mock_request = double(path: '/messages', query_string: 'lang=en&page=2')
      result = LocaleHelper.current_path_with_locale(mock_request, 'ja')
      expect(result).to eq('/messages?lang=ja&page=2')
    end

    it 'handles path with locale prefix' do
      mock_request = double(path: '/ja/messages', query_string: '')
      result = LocaleHelper.current_path_with_locale(mock_request, 'en')
      expect(result).to eq('/messages?lang=en')
    end
  end

  describe '.redirect_path_for_user' do
    context 'when user has non-default locale' do
      let(:user) { double(preferred_language: 'ja') }

      it 'returns localized path' do
        result = LocaleHelper.redirect_path_for_user(user)
        expect(result).to eq('/ja')
      end
    end

    context 'when user has default locale' do
      let(:user) { double(preferred_language: 'en') }

      it 'returns :root_path symbol' do
        result = LocaleHelper.redirect_path_for_user(user)
        expect(result).to eq(:root_path)
      end
    end

    context 'when user has no preferred language' do
      let(:user) { double(preferred_language: '') }

      it 'returns :root_path symbol' do
        result = LocaleHelper.redirect_path_for_user(user)
        expect(result).to eq(:root_path)
      end
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

    it 'does not add default locale prefix' do
      expect(LocaleHelper.add_locale_prefix('/messages', 'en')).to eq('/messages')
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
end
