class LocaleStructureChecker
  class StructureMismatchError < StandardError; end

  def self.check_structure!
    # アプリ定義のlocaleファイルのみを読み込み
    locale_files = load_app_locale_files

    if locale_files.empty?
      puts "[INFO] No locale files found in config/locales/"
      return true
    end

    base_locale = I18n.default_locale.to_s
    base_data = locale_files[base_locale]

    unless base_data
      raise StructureMismatchError, "Base locale file (#{base_locale}.yml) not found"
    end

    base_keys = extract_keys(base_data)
    errors = []

    locale_files.each do |locale, data|
      next if locale == base_locale

      locale_keys = extract_keys(data)

      missing_keys = base_keys - locale_keys
      extra_keys = locale_keys - base_keys

      if missing_keys.any?
        errors << "Missing locale keys in #{locale}: #{missing_keys.join(', ')}"
      end

      if extra_keys.any?
        errors << "Extra locale keys in #{locale}: #{extra_keys.join(', ')}"
      end
    end

    if errors.any?
      raise StructureMismatchError, "Locale structure check failed:\n#{errors.join("\n")}"
    end

    puts "[SUCCESS] All app-defined locale files have consistent structure"
    true
  end

  def self.check_structure_with_warnings
    check_structure!
  rescue StructureMismatchError => e
    e.message.lines.each do |line|
      Rails.logger.warn "[WARNING] #{line.strip}" unless line.strip.empty?
    end
  end

  private

  def self.locale_directory_path
    Rails.root.join('config', 'locales')
  end

  def self.load_app_locale_files
    locale_files = {}
    locale_dir = locale_directory_path

    # config/locales/*.yml ファイルを読み込み
    Dir.glob("#{locale_dir}/*.yml").each do |file_path|
      filename = File.basename(file_path, '.yml')

      # locale名を推測（en, ja等）
      locale = filename.match(/^[a-z]{2}$/) ? filename : filename.split('.').last
      next unless locale&.match?(/^[a-z]{2}$/)

      begin
        data = YAML.load_file(file_path)
        # YAMLファイルのトップレベルキーがlocale名の場合はそのデータを使用
        if data[locale]
          locale_files[locale] = data[locale]
        elsif data.keys.length == 1 && data.keys.first.match?(/^[a-z]{2}$/)
          # トップレベルが別のlocale名の場合
          actual_locale = data.keys.first
          locale_files[actual_locale] = data[actual_locale]
        end
      rescue => e
        Rails.logger.warn "[WARNING] Failed to load #{file_path}: #{e.message}"
      end
    end

    locale_files
  end

  def self.extract_keys(hash, prefix = '')
    keys = []
    hash.each do |key, value|
      current_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
      if value.is_a?(Hash)
        keys.concat(extract_keys(value, current_key))
      else
        keys << current_key
      end
    end
    keys
  end
end
