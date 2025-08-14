require 'capybara/rails'
require 'capybara/cuprite'

def cuprite_options
  lang = ENV['CAPYBARA_LANG'] || 'en'
  browser_options = { 'accept-lang' => lang }

  options = {
    js_errors: true,
    window_size: [1200, 800],
    headless: %w[0 false].exclude?(ENV['HEADLESS']),
    slowmo: ENV['SLOWMO']&.to_f,
    inspector: true,
    browser_options: browser_options,
    process_timeout: 120,
    window_open_timeout: 60,
    pending_connection_errors: false
  }

  # Docker-specific browser options for containerized environments
  if ENV['DOCKER'].present?
    browser_options.merge!({
      'no-sandbox' => nil,           # Required for Docker containers
      'disable-dev-shm-usage' => nil, # Overcome limited resource problems
      'disable-gpu' => nil,          # Disable GPU hardware acceleration
      'headless' => nil              # Run in headless mode for Docker
    })
    options[:headless] = true
    options[:inspector] = false
    options[:browser_path] = '/usr/bin/chromium'
  end

  options
end

# Custom Capybara driver for Chrome/Chromium with Docker support
# This driver is configured to work in both local and Docker environments.
# For Docker environments, set DOCKER environment variable to true.
#
# Documentation reference:
# https://github.com/rubycdp/ferrum?tab=readme-ov-file#customization
Capybara.register_driver(:cuprite_custom) do |app|
  Capybara::Cuprite::Driver.new(app, cuprite_options)
end

# Capybara 設定
Capybara.configure do |config|
  config.test_id = 'data-testid'
  config.default_max_wait_time = 2
  config.default_normalize_ws = true

  if ENV['DOCKER'].present?
    config.server_host = "0.0.0.0"
  end
end

Capybara.javascript_driver = :cuprite_custom

# TODO: Custom selector for test_id attribute
# Capybara.add_selector(:test_id) do
#   css { |value| "[data-testid='#{value}']" }
# end
# Usage: find(:test_id, "foo-bar")
