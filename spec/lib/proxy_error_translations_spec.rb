require 'rails_helper'

RSpec.describe 'Proxy error translations' do
  describe 'English translations' do
    before { I18n.locale = :en }

    it 'has proxy error messages defined' do
      expect(I18n.t('errors.proxy.too_large')).not_to match(/translation missing/)
      expect(I18n.t('errors.proxy.too_large_with_limit', limit: '100MB')).to include('100MB')
      expect(I18n.t('errors.proxy.bad_gateway')).not_to match(/translation missing/)
      expect(I18n.t('errors.proxy.service_unavailable')).not_to match(/translation missing/)
      expect(I18n.t('errors.proxy.gateway_timeout')).not_to match(/translation missing/)
      expect(I18n.t('errors.proxy.generic')).not_to match(/translation missing/)
    end

    it 'handles limit interpolation correctly' do
      message = I18n.t('errors.proxy.too_large_with_limit', limit: '500MB')
      expect(message).to include('500MB')
      expect(message).to include('exceeds')
    end
  end

  describe 'Japanese translations' do
    before { I18n.locale = :ja }

    it 'has proxy error messages defined' do
      expect(I18n.t('errors.proxy.too_large')).not_to match(/translation missing/)
      expect(I18n.t('errors.proxy.too_large_with_limit', limit: '100MB')).to include('100MB')
      expect(I18n.t('errors.proxy.bad_gateway')).not_to match(/translation missing/)
      expect(I18n.t('errors.proxy.service_unavailable')).not_to match(/translation missing/)
      expect(I18n.t('errors.proxy.gateway_timeout')).not_to match(/translation missing/)
      expect(I18n.t('errors.proxy.generic')).not_to match(/translation missing/)
    end

    it 'handles limit interpolation correctly' do
      message = I18n.t('errors.proxy.too_large_with_limit', limit: '500MB')
      expect(message).to include('500MB')
      expect(message).to include('超え')
    end
  end
end