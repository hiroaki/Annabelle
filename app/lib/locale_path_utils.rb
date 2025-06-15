# ロケール付きパス/URLの生成・除去などのコアロジックを提供するモジュール
# インスタンスメソッドとして実装し、mix-inで利用できるようにする
module LocalePathUtils
  # 現在のパスでロケールを変更したURLを生成
  def current_path_with_locale(path, locale)
    path_without_locale = remove_locale_prefix(path)
    add_locale_prefix(path_without_locale, locale)
  end

  # パスからロケールプレフィックスを削除
  def remove_locale_prefix(path)
    return '/' if path.blank? || path == '/'
    validate_path!(path)

    LocaleConfiguration.available_locales.each do |locale|
      locale_str = locale.to_s
      if path.start_with?("/#{locale_str}/")
        return path.sub(%r{^/#{locale_str}}, '')
      elsif path == "/#{locale_str}"
        return '/'
      end
    end

    path
  end

  # パスにロケールプレフィックスを追加
  def add_locale_prefix(path, locale)
    clean_path = remove_locale_prefix(path)
    clean_path = '/' if clean_path.blank?

    "/#{locale}#{clean_path == '/' ? '' : clean_path}"
  end

  private

  def validate_path!(path)
    return if path.blank? # 空文字やnilは許容
    unless path.is_a?(String) && path.start_with?('/') &&
           !path.include?('//') &&
           !path.match?(/[[:cntrl:]\s]/) &&
           !path.split('/').include?('..')
      raise ArgumentError, "Invalid path format: must start with '/', not contain '//', '..', or control characters. Got: #{path.inspect}"
    end
  end
end
