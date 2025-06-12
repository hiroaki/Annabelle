require 'rails_helper'

RSpec.describe LocaleHelper do
  before do
    I18n.default_locale = :en
    allow(I18n).to receive(:available_locales).and_return([:ja, :en])
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
