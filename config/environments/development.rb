require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Make code changes take effect immediately without server restart.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing.
  config.server_timing = true

  # Enable/disable Action Controller caching. By default Action Controller caching is disabled.
  # Run rails dev:cache to toggle Action Controller caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  # Change to :null_store to avoid any caching.
  config.cache_store = :memory_store

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  # config.action_mailer.raise_delivery_errors = false

  # Make template changes take effect immediately.
  config.action_mailer.perform_caching = false

  # Set localhost to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = {
    host: ENV['APP_HTTP_HOST'].presence || 'localhost',
    port: ENV['APP_HTTP_PORT'].presence || 3000,
    protocol: ENV['APP_HTTP_PROTOCOL'].presence || 'http',
  }

  # Specify outgoing SMTP server.
  # NOTE: user_name に空文字を渡すのと、nil を渡すのとでは挙動が異なります。
  # nil では ArgumentError (SMTP-AUTH requested but missing user name) 例外になります。
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              ENV['SMTP_ADDRESS'].presence || 'localhost',
    port:                 ENV['SMTP_PORT'].presence || 1025,
    domain:               ENV['SMTP_DOMAIN'].presence || '',
    user_name:            ENV['SMTP_USERNAME'].presence || '',
    password:             ENV['SMTP_PASSWORD'].presence || '',
    authentication:       :plain,
    enable_starttls_auto: true
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Append comments with runtime information tags to SQL queries in logs.
  config.active_record.query_log_tags_enabled = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # Capybara によるリモートブラウザからのアクセスがコンテナの hosts 情報でアクセスしてくるため、
  # その hosts を明示的に設定するか、または clear しないと、アクセスがブロックされます。
  config.hosts.clear
  # config.hosts << "web"

  # Maximum request body size (in bytes) for form submissions.
  # If your proxy server enforces a request size limit, be sure to set the same value here.
  # (The check on the app side is only for user experience; the actual enforcement is done by the proxy.)
  # フォーム送信時のリクエストサイズ上限（バイト数）。
  # Proxyサーバ側でリクエストサイズ制限がある場合は、必ず同じ値をここにも設定してください。
  # （アプリ側のチェックはユーザー体験向上のための目安であり、実際の制限はProxyで行われます）
  config.x.max_request_body = ENV['MAX_REQUEST_BODY'].presence

  # For Prosopite, the preferred notification channel should be configured
  config.after_initialize do
    Prosopite.rails_logger = true
  end
end
