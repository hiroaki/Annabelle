require 'rails_helper'

RSpec.describe LocaleStructureChecker do
  let(:test_locale_dir) { Rails.root.join('spec', 'fixtures', 'test_locales') }

  # 標準出力をキャプチャするヘルパーメソッド
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  describe '.check_structure!' do
    before do
      allow(I18n).to receive(:default_locale).and_return(:en)
    end

    context 'when locale files have consistent structure' do
      before do
        mock_locale_directory(test_locale_dir)
      end

      it 'does not raise an error' do
        expect { described_class.check_structure! }.to output(
          "[SUCCESS] All app-defined locale files have consistent structure\n"
        ).to_stdout
      end

      it 'prints success message' do
        expect { described_class.check_structure! }.to output(
          "[SUCCESS] All app-defined locale files have consistent structure\n"
        ).to_stdout
      end

      it 'returns true when successful' do
        result = nil
        capture_stdout { result = described_class.check_structure! }
        expect(result).to be true
      end
    end

    context 'when locale files have missing keys' do
      before do
        mock_locale_directory_with_missing_files
      end

      it 'raises StructureMismatchError' do
        expect {
          capture_stdout { described_class.check_structure! }
        }.to raise_error(
          LocaleStructureChecker::StructureMismatchError,
          /Missing locale keys in ja: user\.email/
        )
      end
    end

    context 'when locale files have extra keys' do
      before do
        mock_locale_directory_with_extra_files
      end

      it 'raises StructureMismatchError' do
        expect {
          capture_stdout { described_class.check_structure! }
        }.to raise_error(
          LocaleStructureChecker::StructureMismatchError,
          /Extra locale keys in ja: extra_key, another\.extra/
        )
      end
    end

    context 'when no locale files exist' do
      before do
        mock_empty_locale_directory
      end

      it 'prints info message and returns without error' do
        expect { described_class.check_structure! }.to output(
          "[INFO] No locale files found in config/locales/\n"
        ).to_stdout
      end

      it 'returns true when no files exist' do
        result = nil
        capture_stdout { result = described_class.check_structure! }
        expect(result).to be true
      end
    end

    context 'when base locale file is missing' do
      before do
        mock_locale_directory_with_ja_only
      end

      it 'raises StructureMismatchError' do
        expect {
          capture_stdout { described_class.check_structure! }
        }.to raise_error(
          LocaleStructureChecker::StructureMismatchError,
          'Base locale file (en.yml) not found'
        )
      end
    end

    context 'when YAML file triggers elsif block processing' do
      before do
        mock_locale_directory_with_elsif_files
      end

      it 'processes files correctly through elsif branch' do
        expect { described_class.check_structure! }.to output(
          "[SUCCESS] All app-defined locale files have consistent structure\n"
        ).to_stdout
      end
    end

    context 'when YAML loading encounters errors (rescue branch)' do
      before do
        allow(Rails.logger).to receive(:warn)
        mock_locale_directory_with_invalid_yaml
      end

      it 'handles invalid YAML gracefully (rescue branch)' do
        # 不正なYAMLファイルがあっても処理が継続される
        expect { described_class.check_structure! }.to output(
          "[INFO] No locale files found in config/locales/\n"
        ).to_stdout
      end
    end

    context 'when YAML.load_file raises an exception' do
      before do
        allow(Rails.logger).to receive(:warn)
        # 正常なファイルを用意
        mock_locale_directory(test_locale_dir)
        # YAML.load_fileがエラーを投げるようにモック
        allow(YAML).to receive(:load_file).and_raise(StandardError.new("YAML parsing error"))
      end

      it 'logs warning and continues processing (rescue branch)' do
        expect { described_class.check_structure! }.to output(
          "[INFO] No locale files found in config/locales/\n"
        ).to_stdout

        # 警告ログが出力されることを確認
        expect(Rails.logger).to have_received(:warn).at_least(:once)
      end
    end
  end

  describe '.check_structure_with_warnings' do
    before do
      allow(I18n).to receive(:default_locale).and_return(:en)
      allow(Rails.logger).to receive(:warn)
    end

    context 'when structure check fails' do
      before do
        mock_locale_directory_with_missing_files
      end

      it 'logs warnings instead of raising errors' do
        expect { described_class.check_structure_with_warnings }.not_to raise_error
        expect(Rails.logger).to have_received(:warn).with(
          /\[WARNING\] Missing locale keys in ja: user\.email/
        )
      end
    end

    context 'when structure check passes' do
      before do
        mock_locale_directory(test_locale_dir)
      end

      it 'does not log any warnings' do
        expect { described_class.check_structure_with_warnings }.to output(
          "[SUCCESS] All app-defined locale files have consistent structure\n"
        ).to_stdout
        expect(Rails.logger).not_to have_received(:warn)
      end
    end
  end

  describe '.extract_keys' do
    it 'extracts flat keys' do
      hash = { 'key1' => 'value1', 'key2' => 'value2' }
      keys = described_class.send(:extract_keys, hash)
      expect(keys).to contain_exactly('key1', 'key2')
    end

    it 'extracts nested keys' do
      hash = {
        'level1' => {
          'level2' => {
            'key1' => 'value1',
            'key2' => 'value2'
          }
        }
      }
      keys = described_class.send(:extract_keys, hash)
      expect(keys).to contain_exactly('level1.level2.key1', 'level1.level2.key2')
    end

    it 'handles mixed flat and nested keys' do
      hash = {
        'flat_key' => 'value',
        'nested' => {
          'key1' => 'value1',
          'key2' => 'value2'
        }
      }
      keys = described_class.send(:extract_keys, hash)
      expect(keys).to contain_exactly('flat_key', 'nested.key1', 'nested.key2')
    end

    it 'handles empty hash' do
      keys = described_class.send(:extract_keys, {})
      expect(keys).to be_empty
    end
  end

  describe '.locale_directory_path' do
    it 'returns the correct locale directory path' do
      expected_path = Rails.root.join('config', 'locales')
      expect(described_class.send(:locale_directory_path)).to eq(expected_path)
    end
  end

  private

  # 正常なロケールファイルをモック
  def mock_locale_directory(directory_path = test_locale_dir)
    en_data = YAML.load_file(directory_path.join('en.yml'))
    ja_data = YAML.load_file(directory_path.join('ja.yml'))

    allow(Dir).to receive(:glob).with(anything).and_return([
      Rails.root.join('config', 'locales', 'en.yml').to_s,
      Rails.root.join('config', 'locales', 'ja.yml').to_s
    ])

    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'en.yml').to_s).and_return(en_data)
    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'ja.yml').to_s).and_return(ja_data)
  end

  # 空のディレクトリをモック
  def mock_empty_locale_directory
    allow(Dir).to receive(:glob).with(anything).and_return([])
  end

  # 欠落キーテスト用
  def mock_locale_directory_with_missing_files
    en_data = YAML.load_file(test_locale_dir.join('en_missing.yml'))
    ja_data = YAML.load_file(test_locale_dir.join('ja_missing.yml'))

    allow(Dir).to receive(:glob).with(anything).and_return([
      Rails.root.join('config', 'locales', 'en.yml').to_s,
      Rails.root.join('config', 'locales', 'ja.yml').to_s
    ])

    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'en.yml').to_s).and_return(en_data)
    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'ja.yml').to_s).and_return(ja_data)
  end

  # jaファイルのみのテスト用
  def mock_locale_directory_with_ja_only
    ja_data = YAML.load_file(test_locale_dir.join('ja.yml'))

    allow(Dir).to receive(:glob).with(anything).and_return([
      Rails.root.join('config', 'locales', 'ja.yml').to_s
    ])

    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'ja.yml').to_s).and_return(ja_data)
  end

  # elsifブロックテスト用
  def mock_locale_directory_with_elsif_files
    fr_data = YAML.load_file(test_locale_dir.join('fr.yml'))
    de_data = YAML.load_file(test_locale_dir.join('de.yml'))

    allow(Dir).to receive(:glob).with(anything).and_return([
      Rails.root.join('config', 'locales', 'fr.yml').to_s,
      Rails.root.join('config', 'locales', 'de.yml').to_s
    ])

    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'fr.yml').to_s).and_return(fr_data)
    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'de.yml').to_s).and_return(de_data)
  end

  # 不正なYAMLテスト用
  def mock_locale_directory_with_invalid_yaml
    allow(Dir).to receive(:glob).with(anything).and_return([
      Rails.root.join('config', 'locales', 'invalid.yml').to_s
    ])

    # 不正なYAMLファイルを読み込もうとすると例外が発生する
    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'invalid.yml').to_s).and_raise(StandardError.new("invalid YAML"))
  end

  # 余分なキーのテスト用
  def mock_locale_directory_with_extra_files
    en_data = YAML.load_file(test_locale_dir.join('en.yml'))
    ja_extra_data = YAML.load_file(test_locale_dir.join('ja_extra.yml'))

    allow(Dir).to receive(:glob).with(anything).and_return([
      Rails.root.join('config', 'locales', 'en.yml').to_s,
      Rails.root.join('config', 'locales', 'ja.yml').to_s
    ])

    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'en.yml').to_s).and_return(en_data)
    allow(YAML).to receive(:load_file).with(Rails.root.join('config', 'locales', 'ja.yml').to_s).and_return(ja_extra_data)
  end
end
