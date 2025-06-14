# LocaleConfiguration の初期化設定
# Rails アプリケーション起動時にロケール設定を適用

Rails.application.config.after_initialize do
  # LocaleConfigurationから設定を動的に適用
  Rails.application.config.i18n.available_locales = LocaleConfiguration.available_locales
  Rails.application.config.i18n.default_locale = LocaleConfiguration.default_locale
  
  # I18nの実行時設定も更新
  I18n.available_locales = LocaleConfiguration.available_locales
  I18n.default_locale = LocaleConfiguration.default_locale
  
  # 設定が正常に読み込まれたことをログに出力
  Rails.logger.info "[LocaleConfig] Available locales: #{LocaleConfiguration.available_locales}"
  Rails.logger.info "[LocaleConfig] Default locale: #{LocaleConfiguration.default_locale}"

  # I18n設定との整合性をチェック
  if I18n.available_locales.sort != LocaleConfiguration.available_locales.sort
    Rails.logger.warn "[LocaleConfig] Mismatch detected between I18n.available_locales and LocaleConfiguration.available_locales"
  end
  
  if I18n.default_locale != LocaleConfiguration.default_locale
    Rails.logger.warn "[LocaleConfig] Mismatch detected between I18n.default_locale and LocaleConfiguration.default_locale"
  end
end
