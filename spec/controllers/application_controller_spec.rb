require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'ok'
    end
  end

  describe '#basic_auth_switch_configured?' do
    it 'returns false when ENABLED_BASIC_AUTH is not set' do
      with_env('ENABLED_BASIC_AUTH' => nil) do
        expect(controller.send(:basic_auth_switch_configured?)).to eq(false)
      end
    end

    it 'returns false when ENABLED_BASIC_AUTH is blank' do
      with_env('ENABLED_BASIC_AUTH' => '') do
        expect(controller.send(:basic_auth_switch_configured?)).to eq(false)
      end
    end

    it 'returns true when ENABLED_BASIC_AUTH is present' do
      with_env('ENABLED_BASIC_AUTH' => 'false') do
        expect(controller.send(:basic_auth_switch_configured?)).to eq(true)
      end
    end
  end

  describe '#basic_auth_enabled?' do
    it 'returns false when ENABLED_BASIC_AUTH is not set' do
      with_env('ENABLED_BASIC_AUTH' => nil) do
        expect(controller.send(:basic_auth_enabled?)).to eq(false)
      end
    end

    it 'returns false when ENABLED_BASIC_AUTH is false' do
      with_env('ENABLED_BASIC_AUTH' => 'false') do
        expect(controller.send(:basic_auth_enabled?)).to eq(false)
      end
    end

    it 'returns false when ENABLED_BASIC_AUTH is blank' do
      with_env('ENABLED_BASIC_AUTH' => '') do
        expect(controller.send(:basic_auth_enabled?)).to eq(false)
      end
    end

    it 'returns true when ENABLED_BASIC_AUTH is true' do
      with_env('ENABLED_BASIC_AUTH' => '1') do
        expect(controller.send(:basic_auth_enabled?)).to eq(true)
      end
    end
  end

  describe '#configured_basic_auth_pairs' do
    it 'parses comma-separated BASIC_AUTH_PAIRS into credential pairs when ENABLED_BASIC_AUTH is set' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => 'user1:pass1,user2:pass2',
      ) do
        expect(controller.send(:configured_basic_auth_pairs)).to eq([
          %w[user1 pass1],
          %w[user2 pass2]
        ])
      end
    end

    it 'strips separator whitespace around BASIC_AUTH_PAIRS entries' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => 'user1:pass1, user2:pass2',
      ) do
        expect(controller.send(:configured_basic_auth_pairs)).to eq([
          %w[user1 pass1],
          %w[user2 pass2]
        ])
      end
    end

    it 'returns empty array when BASIC_AUTH_PAIRS is not set' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => nil,
      ) do
        expect(controller.send(:configured_basic_auth_pairs)).to eq([])
      end
    end

    it 'returns empty array when ENABLED_BASIC_AUTH is set and BASIC_AUTH_PAIRS is malformed' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => 'invalid_format',
      ) do
        expect(controller.send(:configured_basic_auth_pairs)).to eq([])
      end
    end
  end
end
