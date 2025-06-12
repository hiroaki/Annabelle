# 外部化されたロケール設定を管理するクラス
# YAMLファイルからの読み込みとキャッシュ機能を提供
class LocaleConfiguration
  include Singleton

  def initialize
    @config_cache = {}
    @cache_timestamp = nil
    reload_config!
  end

  # 利用可能なロケール一覧を取得
  def self.available_locales
    instance.available_locales
  end

  # デフォルトロケールを取得
  def self.default_locale
    instance.default_locale
  end

  # ロケール名（表示用）を取得
  def self.locale_name(locale)
    instance.locale_name(locale)
  end

  # ロケールのネイティブ名を取得
  def self.locale_native_name(locale)
    instance.locale_native_name(locale)
  end

  # 設定の強制リロード
  def self.reload!
    instance.reload_config!
  end

  # キャッシュが有効か確認
  def self.cache_valid?
    instance.cache_valid?
  end

  def available_locales
    ensure_cache_valid!
    @config_cache[:available_locales] ||= begin
      config_data.dig('locales', 'available')&.map(&:to_sym) || [:en, :ja]
    end
  end

  def default_locale
    ensure_cache_valid!
    @config_cache[:default_locale] ||= begin
      default = config_data.dig('locales', 'default')
      default ? default.to_sym : :en
    end
  end

  def locale_name(locale)
    ensure_cache_valid!
    locale_str = locale.to_s
    config_data.dig('locales', 'metadata', locale_str, 'name') || locale_str.capitalize
  end

  def locale_native_name(locale)
    ensure_cache_valid!
    locale_str = locale.to_s
    config_data.dig('locales', 'metadata', locale_str, 'native_name') || locale_name(locale)
  end

  def reload_config!
    @config_cache.clear
    @cache_timestamp = Time.current
    config_data(force_reload: true)
    Rails.logger.info "[LocaleConfiguration] Configuration reloaded at #{@cache_timestamp}"
  end

  def cache_valid?
    return false unless @cache_timestamp
    
    cache_ttl = config_data.dig('cache', 'ttl') || 3600
    Time.current - @cache_timestamp < cache_ttl.seconds
  end

  private

  def ensure_cache_valid!
    reload_config! unless cache_valid?
  end

  def config_data(force_reload: false)
    if force_reload || @config_data.nil?
      config_path = Rails.root.join('config', 'locales.yml')
      if config_path.exist?
        @config_data = YAML.load_file(config_path)
        Rails.logger.debug "[LocaleConfiguration] Loaded config from #{config_path}"
      else
        Rails.logger.warn "[LocaleConfiguration] Config file not found at #{config_path}, using defaults"
        @config_data = default_config
      end
    end
    @config_data
  end

  def default_config
    {
      'locales' => {
        'default' => 'en',
        'available' => ['en', 'ja'],
        'metadata' => {
          'en' => { 'name' => 'English', 'native_name' => 'English' },
          'ja' => { 'name' => 'Japanese', 'native_name' => '日本語' }
        }
      },
      'cache' => {
        'enabled' => true,
        'ttl' => 3600
      }
    }
  end
end
