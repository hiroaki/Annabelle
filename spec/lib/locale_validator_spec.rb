require 'rails_helper'

RSpec.describe LocaleValidator, type: :validator do
  # テスト用のダミーモデルを作成
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :language
      validates :language, locale: true

      def self.name
        'DummyModel'
      end
    end
  end

  let(:dummy_model) { dummy_class.new }

  describe 'バリデーション' do
    context '有効な値の場合' do
      it '有効な文字列ロケールを受け入れる' do
        dummy_model.language = 'ja'
        expect(dummy_model).to be_valid
        expect(dummy_model.errors[:language]).to be_empty
      end

      it '有効なシンボルロケールを受け入れる' do
        dummy_model.language = :en
        expect(dummy_model).to be_valid
        expect(dummy_model.errors[:language]).to be_empty
      end

      it '空文字を受け入れる' do
        dummy_model.language = ''
        expect(dummy_model).to be_valid
        expect(dummy_model.errors[:language]).to be_empty
      end

      it 'nilを受け入れる' do
        dummy_model.language = nil
        expect(dummy_model).to be_valid
        expect(dummy_model.errors[:language]).to be_empty
      end
    end

    context '無効な値の場合' do
      it '存在しないロケール文字列を拒否する' do
        dummy_model.language = 'invalid'
        expect(dummy_model).not_to be_valid
        expect(dummy_model.errors[:language]).to include(I18n.t('errors.locale.invalid_value'))
      end

      it '存在しないロケールシンボルを拒否する' do
        dummy_model.language = :invalid
        expect(dummy_model).not_to be_valid
        expect(dummy_model.errors[:language]).to include(I18n.t('errors.locale.invalid_value'))
      end

      it '数値を拒否する' do
        dummy_model.language = 123
        expect(dummy_model).not_to be_valid
        expect(dummy_model.errors[:language]).to include(I18n.t('errors.locale.invalid_type'))
      end

      it '配列を拒否する' do
        dummy_model.language = ['ja', 'en']
        expect(dummy_model).not_to be_valid
        expect(dummy_model.errors[:language]).to include(I18n.t('errors.locale.invalid_type'))
      end

      it 'ハッシュを拒否する' do
        dummy_model.language = { locale: 'ja' }
        expect(dummy_model).not_to be_valid
        expect(dummy_model.errors[:language]).to include(I18n.t('errors.locale.invalid_type'))
      end

      it 'オブジェクトを拒否する' do
        dummy_model.language = Object.new
        expect(dummy_model).not_to be_valid
        expect(dummy_model.errors[:language]).to include(I18n.t('errors.locale.invalid_type'))
      end
    end

    context 'エラーメッセージの多言語対応' do
      it '日本語環境で適切なエラーメッセージを表示する' do
        I18n.with_locale(:ja) do
          dummy_model.language = 123
          dummy_model.valid?
          expect(dummy_model.errors[:language]).to include('は文字列またはシンボルである必要があります')
        end
      end

      it '英語環境で適切なエラーメッセージを表示する' do
        I18n.with_locale(:en) do
          dummy_model.language = 123
          dummy_model.valid?
          expect(dummy_model.errors[:language]).to include('must be a String or Symbol')
        end
      end
    end
  end

  describe '.valid_locale?' do
    context '有効な値の場合' do
      it '有効な文字列ロケールでtrueを返す' do
        expect(LocaleValidator.valid_locale?('ja')).to be true
        expect(LocaleValidator.valid_locale?('en')).to be true
      end

      it '有効なシンボルロケールでtrueを返す' do
        expect(LocaleValidator.valid_locale?(:ja)).to be true
        expect(LocaleValidator.valid_locale?(:en)).to be true
      end
    end

    context '無効な値の場合' do
      it '空文字でfalseを返す' do
        expect(LocaleValidator.valid_locale?('')).to be false
      end

      it 'nilでfalseを返す' do
        expect(LocaleValidator.valid_locale?(nil)).to be false
      end

      it '存在しないロケール文字列でfalseを返す' do
        expect(LocaleValidator.valid_locale?('invalid')).to be false
      end

      it '存在しないロケールシンボルでfalseを返す' do
        expect(LocaleValidator.valid_locale?(:invalid)).to be false
      end

      it '数値でfalseを返す' do
        expect(LocaleValidator.valid_locale?(123)).to be false
      end

      it '配列でfalseを返す' do
        expect(LocaleValidator.valid_locale?(['ja'])).to be false
      end

      it 'ハッシュでfalseを返す' do
        expect(LocaleValidator.valid_locale?({ locale: 'ja' })).to be false
      end

      it 'オブジェクトでfalseを返す' do
        expect(LocaleValidator.valid_locale?(Object.new)).to be false
      end
    end

    context 'I18n.available_localesとの整合性' do
      it 'LocaleConfiguration.available_localesに含まれる全てのロケールでtrueを返す' do
        LocaleConfiguration.available_locales.each do |locale|
          expect(LocaleValidator.valid_locale?(locale)).to be true
          expect(LocaleValidator.valid_locale?(locale.to_s)).to be true
        end
      end
    end
  end

  describe 'プライベートメソッド' do
    let(:validator) { LocaleValidator.new(attributes: [:language]) }

    describe '#valid_locale_type?' do
      it '文字列でtrueを返す' do
        expect(validator.send(:valid_locale_type?, 'ja')).to be true
      end

      it 'シンボルでtrueを返す' do
        expect(validator.send(:valid_locale_type?, :ja)).to be true
      end

      it '数値でfalseを返す' do
        expect(validator.send(:valid_locale_type?, 123)).to be false
      end

      it '配列でfalseを返す' do
        expect(validator.send(:valid_locale_type?, [])).to be false
      end
    end

    describe '#valid_locale_value?' do
      it '有効なロケール文字列でtrueを返す' do
        expect(validator.send(:valid_locale_value?, 'ja')).to be true
      end

      it '有効なロケールシンボルでtrueを返す' do
        expect(validator.send(:valid_locale_value?, :ja)).to be true
      end

      it '無効なロケール文字列でfalseを返す' do
        expect(validator.send(:valid_locale_value?, 'invalid')).to be false
      end

      it '無効なロケールシンボルでfalseを返す' do
        expect(validator.send(:valid_locale_value?, :invalid)).to be false
      end
    end
  end

  describe 'クラスメソッド版のプライベートメソッド' do
    describe '.valid_locale_type?' do
      it '文字列でtrueを返す' do
        expect(LocaleValidator.send(:valid_locale_type?, 'ja')).to be true
      end

      it 'シンボルでtrueを返す' do
        expect(LocaleValidator.send(:valid_locale_type?, :ja)).to be true
      end

      it '数値でfalseを返す' do
        expect(LocaleValidator.send(:valid_locale_type?, 123)).to be false
      end
    end

    describe '.valid_locale_value?' do
      it '有効なロケール文字列でtrueを返す' do
        expect(LocaleValidator.send(:valid_locale_value?, 'ja')).to be true
      end

      it '有効なロケールシンボルでtrueを返す' do
        expect(LocaleValidator.send(:valid_locale_value?, :ja)).to be true
      end

      it '無効なロケール文字列でfalseを返す' do
        expect(LocaleValidator.send(:valid_locale_value?, 'invalid')).to be false
      end
    end
  end

  describe 'エッジケース' do
    it '空白文字のみの文字列を適切に処理する' do
      dummy_model.language = '   '
      expect(dummy_model).to be_valid  # blank?がtrueになるため
    end

    it 'カスタムオブジェクトは型チェックで適切に拒否される' do
      custom_object = Object.new

      dummy_model.language = custom_object
      expect(dummy_model).not_to be_valid
      expect(dummy_model.errors[:language]).to include(I18n.t('errors.locale.invalid_type'))
    end

    it '同じロケール値でもStringとSymbolの両方で動作する' do
      # String版
      dummy_model.language = 'ja'
      expect(dummy_model).to be_valid

      # Symbol版（新しいインスタンスで）
      dummy_model2 = dummy_class.new
      dummy_model2.language = :ja
      expect(dummy_model2).to be_valid
    end
  end
end
