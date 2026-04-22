require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'ok'
    end
  end

  around do |example|
    ApplicationController.legacy_basic_auth_warning_emitted = false
    example.run
    ApplicationController.legacy_basic_auth_warning_emitted = false
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

    it 'returns true when ENABLED_BASIC_AUTH is true' do
      with_env('ENABLED_BASIC_AUTH' => '1') do
        expect(controller.send(:basic_auth_enabled?)).to eq(true)
      end
    end
  end

  describe '#basic_auth_enabled_legacy?' do
    it 'returns true when legacy credentials are both present' do
      with_env(
        'ENABLED_BASIC_AUTH' => nil,
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => 'legacy_pass'
      ) do
        expect(controller.send(:basic_auth_enabled_legacy?)).to be_truthy
      end
    end

    it 'returns false when only BASIC_AUTH_USER is present' do
      with_env(
        'ENABLED_BASIC_AUTH' => nil,
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => nil
      ) do
        expect(controller.send(:basic_auth_enabled_legacy?)).to be_falsey
      end
    end

    it 'returns false when only BASIC_AUTH_PASSWORD is present' do
      with_env(
        'ENABLED_BASIC_AUTH' => nil,
        'BASIC_AUTH_USER' => nil,
        'BASIC_AUTH_PASSWORD' => 'legacy_pass'
      ) do
        expect(controller.send(:basic_auth_enabled_legacy?)).to be_falsey
      end
    end
  end

  describe '#configured_basic_auth_pairs' do
    it 'parses comma-separated BASIC_AUTH_PAIRS into credential pairs when ENABLED_BASIC_AUTH is set' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => 'user1:pass1,user2:pass2',
        'BASIC_AUTH_USER' => nil,
        'BASIC_AUTH_PASSWORD' => nil
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
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => 'legacy_pass'
      ) do
        expect(controller.send(:configured_basic_auth_pairs)).to eq([])
      end
    end

    it 'returns empty array when ENABLED_BASIC_AUTH is set but BASIC_AUTH_PAIRS is missing' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => nil,
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => 'legacy_pass'
      ) do
        expect(controller.send(:configured_basic_auth_pairs)).to eq([])
      end
    end

    it 'returns empty array when ENABLED_BASIC_AUTH is set and BASIC_AUTH_PAIRS is malformed' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => 'invalid_format',
        'BASIC_AUTH_USER' => nil,
        'BASIC_AUTH_PASSWORD' => nil
      ) do
        expect(controller.send(:configured_basic_auth_pairs)).to eq([])
      end
    end
  end

  describe '#configured_basic_auth_pairs_legacy' do
    it 'returns the legacy pair when both legacy env vars are set' do
      with_env(
        'ENABLED_BASIC_AUTH' => nil,
        'BASIC_AUTH_PAIRS' => nil,
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => 'legacy_pass'
      ) do
        allow(Rails.logger).to receive(:warn)

        expect(controller.send(:configured_basic_auth_pairs_legacy)).to eq([
          ['legacy_user', 'legacy_pass']
        ])
      end
    end

    it 'returns empty array when legacy env is incomplete' do
      with_env(
        'ENABLED_BASIC_AUTH' => nil,
        'BASIC_AUTH_PAIRS' => nil,
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => nil
      ) do
        expect(controller.send(:configured_basic_auth_pairs_legacy)).to eq([])
      end
    end
  end

  describe '#warn_legacy_basic_auth_env_once' do
    it 'warns only once when legacy env is used multiple times' do
      with_env(
        'ENABLED_BASIC_AUTH' => nil,
        'BASIC_AUTH_PAIRS' => nil,
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => 'legacy_pass'
      ) do
        allow(Rails.logger).to receive(:warn)

        2.times { controller.send(:configured_basic_auth_pairs_legacy) }

        expect(Rails.logger).to have_received(:warn).once
      end
    end

    it 'does not warn when BASIC_AUTH_PAIRS is used' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => 'user1:pass1',
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => 'legacy_pass'
      ) do
        allow(Rails.logger).to receive(:warn)

        controller.send(:configured_basic_auth_pairs)

        expect(Rails.logger).not_to have_received(:warn)
      end
    end

    it 'does not warn when ENABLED_BASIC_AUTH is set and legacy env is ignored' do
      with_env(
        'ENABLED_BASIC_AUTH' => '1',
        'BASIC_AUTH_PAIRS' => nil,
        'BASIC_AUTH_USER' => 'legacy_user',
        'BASIC_AUTH_PASSWORD' => 'legacy_pass'
      ) do
        allow(Rails.logger).to receive(:warn)

        controller.send(:configured_basic_auth_pairs)

        expect(Rails.logger).not_to have_received(:warn)
      end
    end
  end
end
