# frozen_string_literal: true

# テスト用のLocaleConfiguration関連ヘルパーメソッド
module LocaleConfigurationHelper
  # テスト用にLocaleConfigurationを一時的に上書きする
  def with_locale_config(config_overrides)
    # 現在の設定を取得し、上書き設定を適用
    merged_config = build_config_from_overrides(config_overrides)
    
    # インスタンスの設定を一時的に上書き
    instance = LocaleConfiguration.instance
    original_config = instance.instance_variable_get(:@config)
    begin
      instance.instance_variable_set(:@config, merged_config)
      # キャッシュをクリア
      instance.instance_variable_set(:@available_locales, nil)
      instance.instance_variable_set(:@default_locale, nil)
      # ブロックを実行
      yield
    ensure
      # 元の設定を復元
      instance.instance_variable_set(:@config, original_config)
      instance.instance_variable_set(:@available_locales, nil)
      instance.instance_variable_set(:@default_locale, nil)
    end
  end
  
  # オーバーライド設定からマージされた設定を生成
  def build_config_from_overrides(config_overrides)
    # デフォルト設定を取得する方法がないため、一時的にカレントの設定を使用
    current_config = nil
    
    # 現在のキャッシュを取得（クラスメソッドを使用）
    current_locales = LocaleConfiguration.available_locales
    current_default = LocaleConfiguration.default_locale
    
    # 設定を再構築する基本構造
    current_config = {
      'locales' => {
        'default' => current_default.to_s,
        'available' => current_locales.map(&:to_s),
        'metadata' => {}
      },
      'cache' => {
        'enabled' => true,
        'ttl' => 3600,
        'development_ttl' => 60
      }
    }
    
    # LocaleConfiguration.locale_nameとlocale_native_nameを使ってmetadataを追加
    current_locales.each do |locale|
      current_config['locales']['metadata'][locale.to_s] = {
        'name' => LocaleConfiguration.locale_name(locale),
        'native_name' => LocaleConfiguration.locale_native_name(locale)
      }
    end
    
    # 深いマージで設定をオーバーライド
    merged_config = current_config
    config_overrides.each do |key, value|
      merged_config = deep_merge_hash(merged_config, key_to_hash(key, value))
    end
    
    merged_config
  end

  private

  # ドット表記のキーをネストしたハッシュに変換
  # 'locales.default', 'ja' => { 'locales' => { 'default' => 'ja' } }
  def key_to_hash(key, value)
    keys = key.to_s.split('.')
    keys.reverse.inject(value) do |hash, key_part|
      { key_part => hash }
    end
  end

  # ハッシュを深いレベルでマージ
  def deep_merge_hash(hash1, hash2)
    hash1.deep_merge(hash2) do |_key, old_val, new_val|
      if old_val.is_a?(Array) && new_val.is_a?(Array)
        new_val
      elsif old_val.is_a?(Hash) && new_val.is_a?(Hash)
        deep_merge_hash(old_val, new_val)
      else
        new_val
      end
    end
  end
end

RSpec.configure do |config|
  config.include LocaleConfigurationHelper
end
