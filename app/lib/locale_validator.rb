# ロケール値のバリデーションを行うRails標準のカスタムバリデーター
class LocaleValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? # 空値は他のバリデーションに委ねる

    unless valid_locale_type?(value)
      record.errors.add(attribute, I18n.t('errors.locale.invalid_type'))
      return
    end

    unless valid_locale_value?(value)
      record.errors.add(attribute, I18n.t('errors.locale.invalid_value'))
    end
  end

  # クラスメソッドとしても使用可能にする
  def self.valid_locale?(locale)
    return false if locale.blank?
    return false unless valid_locale_type?(locale)
    valid_locale_value?(locale)
  end

  private

  def valid_locale_type?(value)
    value.is_a?(String) || value.is_a?(Symbol)
  end

  def valid_locale_value?(value)
    I18n.available_locales.map(&:to_s).include?(value.to_s)
  end

  # クラスメソッド版
  class << self
    private

    def valid_locale_type?(value)
      value.is_a?(String) || value.is_a?(Symbol)
    end

    def valid_locale_value?(value)
      I18n.available_locales.map(&:to_s).include?(value.to_s)
    end
  end
end
