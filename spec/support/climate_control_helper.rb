require 'climate_control'

# Helper to temporarily modify ENV variables in tests
# Usage: with_env('ENABLE_2FA' => nil) { ... }
def with_env(env_vars, &block)
  ClimateControl.modify(env_vars, &block)
end
