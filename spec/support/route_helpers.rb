module RouteHelpers
  # テスト用のロケール付きルートヘルパー
  def test_locale
    :en # テストではデフォルトで英語を使用
  end

  # 既存のルートヘルパーメソッドをオーバーライドして、自動的にロケールを追加
  def method_missing(method_name, *args, **options)
    if method_name.to_s.end_with?('_path', '_url') && respond_to_missing?(method_name, false)
      # ロケールパラメータを自動的に追加
      options = options.merge(locale: test_locale) unless options.key?(:locale)
      super(method_name, *args, **options)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.end_with?('_path', '_url') || super
  end
end

RSpec.configure do |config|
  config.include RouteHelpers, type: :request
  config.include RouteHelpers, type: :system
end
