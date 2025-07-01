require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#in_configuration_layout?' do
    before do
      allow(helper).to receive(:user_signed_in?).and_return(true)
    end

    it 'returns true for registrations controller' do
      allow(helper).to receive(:controller_name).and_return('registrations')
      expect(helper.in_configuration_layout?).to be true
    end

    it 'returns true for users controller' do
      allow(helper).to receive(:controller_name).and_return('users')
      expect(helper.in_configuration_layout?).to be true
    end

    it 'returns true for two_factor_settings controller' do
      allow(helper).to receive(:controller_name).and_return('two_factor_settings')
      expect(helper.in_configuration_layout?).to be true
    end

    it 'returns false for other controllers' do
      allow(helper).to receive(:controller_name).and_return('messages')
      expect(helper.in_configuration_layout?).to be false
    end

    it 'returns false if user is not signed in' do
      allow(helper).to receive(:user_signed_in?).and_return(false)
      allow(helper).to receive(:controller_name).and_return('users')
      expect(helper.in_configuration_layout?).to be false
    end
  end
end
