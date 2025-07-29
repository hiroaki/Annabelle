require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'ok'
    end
  end

  describe '#valid_user' do
    around do |example|
      orig = ENV['BASIC_AUTH_USER']
      example.run
      ENV['BASIC_AUTH_USER'] = orig
    end

    it 'returns presence when BASIC_AUTH_USER is set' do
      ENV['BASIC_AUTH_USER'] = 'user1'
      expect(controller.send(:valid_user)).to eq 'user1'
    end

    it 'returns nil when BASIC_AUTH_USER is not set' do
      ENV.delete('BASIC_AUTH_USER')
      expect(controller.send(:valid_user)).to be_nil
    end
  end

  describe '#valid_pswd' do
    around do |example|
      orig = ENV['BASIC_AUTH_PASSWORD']
      example.run
      ENV['BASIC_AUTH_PASSWORD'] = orig
    end

    it 'returns presence when BASIC_AUTH_PASSWORD is set' do
      ENV['BASIC_AUTH_PASSWORD'] = 'secret'
      expect(controller.send(:valid_pswd)).to eq 'secret'
    end

    it 'returns nil when BASIC_AUTH_PASSWORD is not set' do
      ENV.delete('BASIC_AUTH_PASSWORD')
      expect(controller.send(:valid_pswd)).to be_nil
    end
  end
end
