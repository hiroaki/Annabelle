# This file is copied to spec/ when you run 'rails generate rspec:install'

# Load and launch SimpleCov at the very top of your test/test_helper.rb
# (or spec_helper.rb, rails_helper, cucumber env.rb,
# or whatever your preferred test framework uses):
require 'simplecov'
SimpleCov.start 'rails'

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Rails.application.load_seed if Rails.env.test?

#--
# Capybara の設定ここから
#
require 'capybara/rails'
require 'capybara/cuprite'

# Custom Capybara driver for Chrome/Chromium with Docker support
# This driver is configured to work in both local and Docker environments.
# For Docker environments, set DOCKER environment variable to true.
# 
# Documentation reference:
# https://github.com/rubycdp/ferrum?tab=readme-ov-file#customization
Capybara.register_driver(:cuprite_custom) do |app|
  lang = ENV['CAPYBARA_LANG'] || 'en'
  
  # Base browser options with language setting
  browser_options = { 'accept-lang' => lang }
  
  # Docker-specific browser options for containerized environments
  if ENV['DOCKER'].present?
    browser_options.merge!({
      'no-sandbox' => nil,           # Required for Docker containers
      'disable-dev-shm-usage' => nil, # Overcome limited resource problems
      'disable-gpu' => nil,          # Disable GPU hardware acceleration
      'headless' => nil              # Run in headless mode for Docker
    })
  end

  options = {
    js_errors: true,
    window_size: [1200, 800],
    headless: ENV['DOCKER'].present? ? true : %w[0 false].exclude?(ENV['HEADLESS']),
    slowmo: ENV['SLOWMO']&.to_f,
    inspector: !ENV['DOCKER'].present?, # Disable inspector in Docker
    browser_options: browser_options,
    process_timeout: 120,
    window_open_timeout: 60,
    pending_connection_errors: false
  }

  # Set browser path for Docker environment (Chromium)
  if ENV['DOCKER'].present?
    options[:browser_path] = '/usr/bin/chromium'
  end

  puts "Capybara::Cuprite::Driver options: #{options}" if ENV['DEBUG_CAPYBARA']

  Capybara::Cuprite::Driver.new(app, options)
end

# Configure Capybara for different environments
Capybara.configure do |config|
  config.test_id = 'data-testid'
  config.default_max_wait_time = 10
  config.default_normalize_ws = true
  
  # Docker environment specific configuration
  if ENV['DOCKER'].present?
    config.server_host = "0.0.0.0"
    config.server_port = 3000
    config.app_host = "http://web:3000" if ENV['COMPOSE_SERVICE_NAME'] == 'web'
  else
    # Local development - use a different port to avoid conflicts
    config.server_port = 3001
  end
end

# Set the JavaScript driver
Capybara.javascript_driver = :cuprite_custom

# Debug information for Docker environments
if ENV['DOCKER'].present? && ENV['DEBUG_CAPYBARA']
  puts "=== Capybara Configuration ==="
  puts "Capybara.javascript_driver: #{Capybara.javascript_driver}"
  puts "Capybara.server_host: #{Capybara.server_host}"
  puts "Capybara.server_port: #{Capybara.server_port}"
  puts "Capybara.app_host: #{Capybara.app_host}"
  puts "=============================="
end

# TODO: Custom selector for test_id attribute
# Capybara.add_selector(:test_id) do
#   css { |value| "[data-testid='#{value}']" }
# end
# Usage: find(:test_id, "foo-bar")
#
# Capybara の設定ここまで
#--

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/7-1/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  #
  config.include FactoryBot::Syntax::Methods
  config.include ActionDispatch::TestProcess
  config.include OmniauthMacros # in support directory

  config.include Warden::Test::Helpers
  config.after(type: :system) { Warden.test_reset! }
  config.after(type: :request) { Warden.test_reset! } # request でも使うなら

  # https://github.com/thoughtbot/shoulda-matchers/tree/v6.4.0?tab=readme-ov-file#rails-apps
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  # Deviseのテストヘルパーを使用可能にする
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Capybara 用の自作ヘルパー
  config.include CapybaraHelpers, type: :system

  # I18n に関するメッセージを組み立てるための自作ヘルパー
  config.include ExpectErrorMessageHelper

  # system spec の設定
  config.before(:each, type: :system) do |example|
    driven_by(:cuprite_custom)
    ActiveJob::Base.queue_adapter = :inline
  end

  # ロケール設定
  config.before(:each) do
    I18n.locale = :en
    Rails.application.routes.default_url_options[:locale] = :en
  end

  # OmniAuth テスト設定
  config.before(:each) do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = nil
  end

  # Docker環境でのCapybaraセッション管理（一時的に無効化）
  # if ENV['CAPYBARA_APP_HOST'].present?
  #   config.before(:each, type: :system) do |example|
  #     # 既存のセッションをクリア
  #     Capybara.reset_sessions!
  #   end
  #   
  #   config.after(:each, type: :system) do |example|
  #     # テスト後にセッションをクリア
  #     Capybara.reset_sessions!
  #   end
  # end

  # config.before(:each, type: :job) do
  #   ActiveJob::Base.queue_adapter = :test
  # end
end
