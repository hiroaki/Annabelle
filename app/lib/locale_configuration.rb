# 外部化されたロケール設定を管理するクラス
# YAMLファイルからの読み込みと設定へのアクセスを提供
class LocaleConfiguration
  include Singleton

  def initialize
    load_config
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

  def available_locales
    @available_locales ||= @config.dig('locales', 'available').map(&:to_sym)
  end

  def default_locale
    @default_locale ||= @config.dig('locales', 'default').to_sym
  end

  def locale_name(locale)
    locale_str = locale.to_s
    metadata = @config.dig('locales', 'metadata', locale_str)
    
    if metadata && metadata['name']
      metadata['name']
    else
      # 未知のロケールは大文字で始まるように（互換性維持）
      locale_str.capitalize
    end
  end

  def locale_native_name(locale)
    locale_str = locale.to_s
    metadata = @config.dig('locales', 'metadata', locale_str)
    
    if metadata && metadata['native_name']
      metadata['native_name']
    else
      # 代替としてロケール名を返す（互換性維持）
      locale_name(locale)
    end
  end

  private

  def load_config
    config_path = Rails.root.join('config', 'locales.yml')
    unless config_path.exist?
      raise "Configuration file not found: #{config_path}. Please ensure 'config/locales.yml' exists."
    end
    
    @config = YAML.load_file(config_path)
    
    # 必須の設定キーが存在するか検証
    validate_config!
    
    Rails.logger.debug "[LocaleConfiguration] Loaded config from #{config_path}"
  end
  
  # 最低限必要な設定が含まれているか検証
  def validate_config!
    unless @config.dig('locales', 'available').is_a?(Array) && !@config.dig('locales', 'available').empty?
      raise "Missing or invalid 'locales.available' setting in config/locales.yml"
    end
    
    unless @config.dig('locales', 'default').is_a?(String)
      raise "Missing or invalid 'locales.default' setting in config/locales.yml"
    end
    
    unless @config.dig('locales', 'metadata').is_a?(Hash)
      raise "Missing or invalid 'locales.metadata' setting in config/locales.yml"
    end
  end
end
