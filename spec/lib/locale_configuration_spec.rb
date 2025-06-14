# frozen_string_literal: true

require 'rails_helper'

describe LocaleConfiguration do
  # LocaleConfigurationヘルパーは自動的にインクルードされます

  describe '.available_locales' do
    it '利用可能なロケール一覧を返す' do
      expect(LocaleConfiguration.available_locales).to match_array([:en, :ja])
    end
  end

  describe '.default_locale' do
    it 'デフォルトロケールを返す' do
      expect(LocaleConfiguration.default_locale).to eq(:en)
    end
  end

  describe '.locale_name' do
    it '指定したロケールの表示名を返す' do
      expect(LocaleConfiguration.locale_name(:en)).to eq('English')
      expect(LocaleConfiguration.locale_name(:ja)).to eq('Japanese')
    end

    it '未知のロケールが指定された場合はロケールコードの先頭を大文字にして返す' do
      expect(LocaleConfiguration.locale_name(:es)).to eq('Es')
    end
  end

  describe '.locale_native_name' do
    it '指定したロケールのネイティブ名を返す' do
      expect(LocaleConfiguration.locale_native_name(:en)).to eq('English')
      expect(LocaleConfiguration.locale_native_name(:ja)).to eq('日本語')
    end

    it '未知のロケールが指定された場合はlocale_nameの結果を返す' do
      expect(LocaleConfiguration.locale_native_name(:es)).to eq('Es')
    end
  end
  
  describe 'with_locale_config helper' do
    it '一時的に設定を変更できる' do
      original_default = LocaleConfiguration.default_locale
      
      # 設定を一時的に変更してテスト
      with_locale_config('locales.default' => 'ja') do
        expect(LocaleConfiguration.default_locale).to eq(:ja)
      end
      
      # テスト後は元の設定に戻っている
      expect(LocaleConfiguration.default_locale).to eq(original_default)
    end
    
    it '複数の設定を一度に変更できる' do
      with_locale_config(
        'locales.default' => 'ja',
        'locales.available' => ['ja', 'en', 'fr']
      ) do
        expect(LocaleConfiguration.default_locale).to eq(:ja)
        expect(LocaleConfiguration.available_locales).to match_array([:ja, :en, :fr])
      end
    end
  end
  
  describe 'validation errors' do
    context 'when configuration file validation fails' do
      it "raises an error when 'locales.available' is not an array" do
        expect {
          with_locale_config('locales.available' => nil) do
            LocaleConfiguration.instance.send(:validate_config!)
          end
        }.to raise_error(RuntimeError, /Missing or invalid 'locales.available' setting/)
      end

      it "raises an error when 'locales.available' is an empty array" do
        expect {
          with_locale_config('locales.available' => []) do
            LocaleConfiguration.instance.send(:validate_config!)
          end
        }.to raise_error(RuntimeError, /Missing or invalid 'locales.available' setting/)
      end

      it "raises an error when 'locales.default' is not a string" do
        expect {
          with_locale_config('locales.default' => nil) do
            LocaleConfiguration.instance.send(:validate_config!)
          end
        }.to raise_error(RuntimeError, /Missing or invalid 'locales.default' setting/)
      end

      it "raises an error when 'locales.metadata' is not a hash" do
        expect {
          with_locale_config('locales.metadata' => nil) do
            LocaleConfiguration.instance.send(:validate_config!)
          end
        }.to raise_error(RuntimeError, /Missing or invalid 'locales.metadata' setting/)
      end
    end

    context 'when configuration file does not exist' do
      it 'raises an error when configuration file does not exist' do
        original_root = Rails.root
        original_instance = LocaleConfiguration.instance_variable_defined?(:@instance) ? 
                           LocaleConfiguration.instance_variable_get(:@instance) : 
                           nil

        begin
          fake_path = Pathname.new('/non_existent_path')
          allow(Rails).to receive(:root).and_return(fake_path)
          if LocaleConfiguration.instance_variable_defined?(:@instance)
            LocaleConfiguration.remove_instance_variable(:@instance)
          end

          expect {
            LocaleConfiguration.instance.send(:load_config)
          }.to raise_error(RuntimeError, /Configuration file not found/)
        ensure
          allow(Rails).to receive(:root).and_call_original
          if original_instance
            LocaleConfiguration.instance_variable_set(:@instance, original_instance)
          end
        end
      end
    end
  end
end
