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
Capybara.javascript_driver = :cuprite_custom
Capybara.register_driver(:cuprite_custom) do |app|
  # see also https://github.com/rubycdp/ferrum?tab=readme-ov-file#customization
  Capybara::Cuprite::Driver.new(app,
    js_errors: true,
    window_size: [1200, 800],
    headless: %w[0 false].exclude?(ENV['HEADLESS']),
    slowmo: ENV['SLOWMO']&.to_f,
    inspector: true,
    browser_options: ENV['DOCKER'] ? { 'no-sandbox' => nil } : {},
  )
end

# if you use Docker don't forget to pass no-sandbox option:
#Capybara::Cuprite::Driver.new(app, browser_options: { 'no-sandbox': nil })

# 要素を特定するために、この属性を使います。
# 要素に埋め込むためのヘルパー TestHelper の内容も参照してください。
Capybara.configure do |config|
  config.test_id = 'data-testid'
end
# TODO: 単に find したい場合はカスタムのセレクタを導入することができます。
# #==> find(:test_id, "foo-bar")
# Capybara.add_selector(:test_id) do
#   css { |value| "[data-testid='#{value}']" }
# end

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

  # system spec ではジョブを動かします。
  config.before(:each, type: :system) do
    ActiveJob::Base.queue_adapter = :inline
  end

  # config.before(:each, type: :job) do
  #   ActiveJob::Base.queue_adapter = :test
  # end
end
