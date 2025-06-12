require 'rails_helper'

RSpec.describe LocaleUrlHelper do
  before do
    I18n.default_locale = LocaleConfiguration.default_locale
    allow(I18n).to receive(:available_locales).and_return(LocaleConfiguration.available_locales)
  end

  describe '.current_path_with_locale_path' do
    let(:mock_request) { double(path: '/messages', query_string: 'page=2') }

    it 'generates path-based locale URL' do
      result = LocaleUrlHelper.current_path_with_locale_path(mock_request, 'ja')
      expect(result).to eq('/ja/messages')
    end

    it 'handles default locale (explicit locale required)' do
      result = LocaleUrlHelper.current_path_with_locale_path(mock_request, 'en')
      expect(result).to eq('/en/messages')
    end

    it 'handles root path' do
      mock_request = double(path: '/', query_string: '')
      result = LocaleUrlHelper.current_path_with_locale_path(mock_request, 'ja')
      expect(result).to eq('/ja')
    end
  end

  describe '.current_path_with_locale_query' do
    let(:mock_request) { double(path: '/messages', query_string: 'page=2') }

    it 'generates path-based locale URL (step 4: unified strategy)' do
      result = LocaleUrlHelper.current_path_with_locale_query(mock_request, 'ja')
      expect(result).to eq('/ja/messages')
    end
  end

  describe '.current_path_with_locale_unified' do
    let(:mock_request) { double(path: '/messages', query_string: 'page=2') }

    context 'after step 4: unified to path-based strategy' do
      it 'uses path-based approach' do
        result = LocaleUrlHelper.current_path_with_locale_unified(mock_request, 'ja')
        expect(result).to eq('/ja/messages')
      end
    end
  end

  describe '.localized_path_for' do
    before do
      allow(Rails.application.routes.url_helpers).to receive(:edit_user_path).with(id: 1).and_return('/users/1/edit')
      allow(Rails.application.routes.url_helpers).to receive(:edit_user_path).with(id: 1, locale: 'ja').and_return('/ja/users/1/edit')
    end

    context 'when path-based locale is disabled' do
      before do
        allow(LocaleUrlHelper).to receive(:use_path_based_locale?).and_return(false)
      end

      it 'generates query-based URL for non-default locale' do
        result = LocaleUrlHelper.localized_path_for(:edit_user_path, 'ja', id: 1)
        expect(result).to eq('/users/1/edit?lang=ja')
      end

      it 'generates clean URL for default locale' do
        result = LocaleUrlHelper.localized_path_for(:edit_user_path, 'en', id: 1)
        expect(result).to eq('/users/1/edit')
      end
    end

    context 'when path-based locale is enabled' do
      before do
        allow(LocaleUrlHelper).to receive(:use_path_based_locale?).and_return(true)
      end

      it 'generates path-based URL for non-default locale' do
        result = LocaleUrlHelper.localized_path_for(:edit_user_path, 'ja', id: 1)
        expect(result).to eq('/ja/users/1/edit')
      end

      it 'generates clean URL for default locale' do
        result = LocaleUrlHelper.localized_path_for(:edit_user_path, 'en', id: 1)
        expect(result).to eq('/users/1/edit')
      end
    end
  end

  describe '.use_path_based_locale?' do
    context 'when config is not set' do
      before do
        allow(Rails.application.config).to receive(:respond_to?).with(:x).and_return(false)
      end

      it 'returns false' do
        expect(LocaleUrlHelper.use_path_based_locale?).to be false
      end
    end

    context 'when config is set to true' do
      before do
        config_x = double('config_x')
        allow(config_x).to receive(:respond_to?).with(:use_path_based_locale).and_return(true)
        allow(config_x).to receive(:use_path_based_locale).and_return(true)

        allow(Rails.application.config).to receive(:respond_to?).with(:x).and_return(true)
        allow(Rails.application.config).to receive(:respond_to?).with(:x, anything).and_return(true)
        allow(Rails.application.config).to receive(:x).and_return(config_x)
      end

      it 'returns true' do
        expect(LocaleUrlHelper.use_path_based_locale?).to be true
      end
    end
  end

  describe '.base_link_classes' do
    before do
      allow(I18n).to receive(:locale).and_return(:ja)
    end

    it 'includes font-bold for current locale' do
      result = LocaleUrlHelper.base_link_classes(:ja)
      expect(result).to include('font-bold')
    end

    it 'does not include font-bold for non-current locale' do
      result = LocaleUrlHelper.base_link_classes(:en)
      expect(result).not_to include('font-bold')
    end

    it 'includes additional classes' do
      result = LocaleUrlHelper.base_link_classes(:ja, 'custom-class')
      expect(result).to include('custom-class')
    end
  end
end
