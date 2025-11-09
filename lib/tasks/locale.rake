namespace :locale do
  desc 'Check locale file structure consistency'
  task check: :environment do
    LocaleStructureChecker.check_structure!
  end

  desc 'Show locale structure differences'
  task diff: :environment do
    locale_files = LocaleStructureChecker.send(:load_app_locale_files)

    if locale_files.empty?
      puts '[INFO] No locale files found in config/locales/'
      return
    end

    base_locale = I18n.default_locale.to_s
    base_data = locale_files[base_locale]

    unless base_data
      puts "[ERROR] Base locale file (#{base_locale}.yml) not found"
      return
    end

    base_keys = LocaleStructureChecker.send(:extract_keys, base_data)

    puts "Base locale (#{base_locale}) has #{base_keys.length} keys (app-defined only)"
    puts '=' * 60

    locale_files.each do |locale, data|
      next if locale == base_locale

      locale_keys = LocaleStructureChecker.send(:extract_keys, data)

      missing_keys = base_keys - locale_keys
      extra_keys = locale_keys - base_keys

      puts "\n#{locale.upcase} locale:"
      puts "  Total keys: #{locale_keys.length}"

      if missing_keys.any?
        puts "  [Missing] keys (#{missing_keys.length}):"
        missing_keys.sort.each { |key| puts "    - #{key}" }
      end

      if extra_keys.any?
        puts "  [Extra] keys (#{extra_keys.length}):"
        extra_keys.sort.each { |key| puts "    + #{key}" }
      end

      if missing_keys.empty? && extra_keys.empty?
        puts '  [Perfect] match with base locale'
      end
    end
  end
end
