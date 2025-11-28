# This class manages the configuration for Two Factor Authentication, specifically
# the encryption keys required for ActiveRecord encryption.
#
# It is designed to be loaded early in the application boot process (in config/application.rb)
# to determine if encryption should be enabled or if the application should fail fast
# due to partial configuration.
module TwoFactor
  class Configuration
    def self.enabled?
      primary_key.present? && deterministic_key.present? && key_derivation_salt.present?
    end

    # Returns true if any of the related ENV keys are present (partial or full).
    def self.any_configured?
      primary_key.present? || deterministic_key.present? || key_derivation_salt.present?
    end

    def self.primary_key
      ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY']
    end

    def self.deterministic_key
      ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY']
    end

    def self.key_derivation_salt
      ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT']
    end
  end
end
