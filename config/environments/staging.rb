# Use the production environment settings as a base
# and override only the staging environment-specific settings.
# production 環境の設定をベースにし、 staging 環境固有の設定のみオーバーライドするようにします。
require_relative "production"

Rails.application.configure do
  config.log_level = :debug

  # Since these values are set by environment variables,
  # the description here will be the same in both production and staging environments.
  # これらの値は環境変数によって設定されるため、
  # 本番環境でもステージング環境でもここでの記述は同じ内容になります。
  #
  # config.action_mailer.default_url_options = {
  #   host: ENV['APP_HTTP_HOST'] || 'localhost',
  #   port: ENV['APP_HTTP_PORT'] || 3000,
  #   protocol: ENV['APP_HTTP_PROTOCOL'] || 'https',
  # }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_ADDRESS'],
    port: ENV['SMTP_PORT'],
  }

  # Temporary configuration: Currently, we are trying to see if the deployment can be completed properly with the http configuration.
  # 仮設定：現在はまず http での構成でデプロイがただしく完了できるかを試しています。
  #
  # The ultimate goal is to operate over https, in which case assume_ssl and force_ssl will be set to true.
  # 最終目標は https で運用することで、その際は assume_ssl および force_ssl は true に設定する予定です。

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = false

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false
end
