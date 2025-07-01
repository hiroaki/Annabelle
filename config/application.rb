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

    # activerecord-session_store (gem) settings
    ActiveRecord::SessionStore::Session.serializer = :json

    # rails-i18n (gem) settings
    # デフォルトは既存の設定を保持し、初期化時に動的に設定
    config.i18n.available_locales = [:en, :ja]
    config.i18n.default_locale = :en

    # Use environment variable to select image processing backend (mini_magick or vips)
    valid_processors = [:mini_magick, :vips]
    processor = ENV.fetch("ANNABELLE_VARIANT_PROCESSOR", "mini_magick").to_sym
    unless valid_processors.include?(processor)
      warn "[Annabelle] ANNABELLE_VARIANT_PROCESSOR='#{processor}' is invalid. Falling back to :mini_magick."
      processor = :mini_magick
    end
    config.active_storage.variant_processor = processor

    # My experimental feature
    config.x.auto_login = config_for(Rails.root.join('config/x/auto_login.yml'))

    # Active Job の中でテンプレートを render する際に URL ヘルパーが使えるようにします。
    # action_mailer 用の設定を複製し、両者で同じ URL になるようにしています。
    #
    # Job における default_url_options について（このやり方は期待通り働かず）：
    # https://github.com/rails/rails/issues/29992#issuecomment-318819265
    # その他参考：
    # https://github.com/rails/rails/issues/39566
    config.after_initialize do
      Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options.dup
    end
  end
end
