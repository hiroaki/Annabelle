require 'rails_helper'

RSpec.describe LocalePathUtils do
  include LocalePathUtils
  before do
    I18n.default_locale = LocaleConfiguration.default_locale
    allow(I18n).to receive(:available_locales).and_return(LocaleConfiguration.available_locales)
  end

  describe '#current_path_with_locale' do
    it 'generates path-based locale URL for non-default locale' do
      result = current_path_with_locale('/messages', 'ja')
      expect(result).to eq('/ja/messages')
    end

    it 'generates default locale URL with prefix' do
      result = current_path_with_locale('/messages', 'en')
      expect(result).to eq('/en/messages')
    end

    it 'handles path with existing locale prefix' do
      result = current_path_with_locale('/ja/messages', 'en')
      expect(result).to eq('/en/messages')
    end

    it 'handles root path correctly' do
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

    it 'handles locale-only path' do
      expect(remove_locale_prefix('/ja')).to eq('/')
      expect(remove_locale_prefix('/en')).to eq('/')
    end

    it 'handles path without locale prefix' do
      expect(remove_locale_prefix('/messages')).to eq('/messages')
      expect(remove_locale_prefix('/')).to eq('/')
    end

    it 'handles blank or nil path' do
      expect(remove_locale_prefix('')).to eq('/')
      expect(remove_locale_prefix(nil)).to eq('/')
    end

    it 'fixes double slashes' do
      expect(remove_locale_prefix('//ja//messages')).to eq('/messages')
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

    it 'removes existing locale before adding new one' do
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
end
