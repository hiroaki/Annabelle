# config/environments/staging.rb
# production 環境の設定をベースにし、 staging 環境固有の設定のみオーバーライドするようにします。
require_relative "production"

Rails.application.configure do
  # staging 環境固有の設定をこのブロックに追加します。

  # production は :info
  config.log_level = :debug

  # 環境変数から設定するようにしているため production も staging も同じでよいです。
  #
  # config.action_mailer.default_url_options = {
  #   host: ENV['APP_HTTP_HOST'] || 'localhost',
  #   port: ENV['APP_HTTP_PORT'] || 3000,
  #   protocol: ENV['APP_HTTP_PROTOCOL'] || 'https',
  # }

  # 環境変数から設定するようにしているため production も staging も同じでよいです。
  #
  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.smtp_settings = {
  #   address:              ENV['SMTP_ADDRESS'] || 'localhost',
  #   port:                 ENV['SMTP_PORT'] || 1025,
  #   domain:               ENV['SMTP_DOMAIN'], # HELO
  #   user_name:            ENV['SMTP_USERNAME'],
  #   password:             ENV['SMTP_PASSWORD'],
  #   authentication:       :plain,
  #   enable_starttls_auto: true
  # }
end
