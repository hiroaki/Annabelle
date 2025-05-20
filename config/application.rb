require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Annabelle
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Secrets configured for ActiveRecord encrypted attributes
    config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]

    # activerecord-session_store
    ActiveRecord::SessionStore::Session.serializer = :json
  end

  # Set default_url_options For Entire Application
  # https://github.com/jbranchaud/til/blob/master/rails/set-default-url-options-for-entire-application.md
  Rails.application.default_url_options = {
    host: ENV['ANNABELLE_HOST'].presence || 'localhost',
    port: ENV['ANNABELLE_PORT'].presence,
  }

  # My experimental feature
  Rails.application.configure do
    config.x.auto_login = config_for(Rails.root.join('config/x/auto_login.yml'))
  end
end
