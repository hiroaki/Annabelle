module TwoFactorAuthHelper
  # Delegate availability check to the service for testability and reuse
  def two_factor_auth_available?
    TwoFactor::Configuration.enabled?
  end
end
