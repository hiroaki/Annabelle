require 'rails_helper'

RSpec.describe TwoFactor::Configuration do
  around do |example|
    # Use ClimateControl to temporarily modify ENV for the example.
    ClimateControl.modify(
      'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => nil,
      'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => nil,
      'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => nil
    ) do
      example.run
    end
  end

  describe '.enabled?' do
    it 'returns true when all required ENV vars are present' do
      ClimateControl.modify(
        'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary',
        'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'det',
        'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'salt'
      ) do
        expect(described_class.enabled?).to be true
      end
    end

    it 'returns false when any required ENV var is missing' do
      ClimateControl.modify(
        'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary',
        'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => nil,
        'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'salt'
      ) do
        expect(described_class.enabled?).to be false
      end
    end

    it 'returns false when none of the ENV vars are present' do
      expect(described_class.enabled?).to be false
    end
  end

  describe '.any_configured?' do
    it 'returns true when all required ENV vars are present' do
      ClimateControl.modify(
        'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary',
        'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'det',
        'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'salt'
      ) do
        expect(described_class.any_configured?).to be true
      end
    end

    it 'returns true when some required ENV vars are present' do
      ClimateControl.modify(
        'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary',
        'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => nil,
        'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => nil
      ) do
        expect(described_class.any_configured?).to be true
      end
    end

    it 'returns false when none of the ENV vars are present' do
      expect(described_class.any_configured?).to be false
    end
  end
end
