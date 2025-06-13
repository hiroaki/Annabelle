# Locale System - リファクタリング完了版

## 概要

Annabelleのロケールシステムは以下の特徴を持つ統一されたアーキテクチャです：

- **パスベースURL戦略**: 明示的ロケール必須化（例: `/ja/users`, `/en/users`）
- **外部設定管理**: `config/locales.yml` による設定の一元化
- **OAuth特別対応**: セッションベースフォールバック機能
- **簡素化されたロジック**: 統一された優先順位とフォールバック戦略

## アーキテクチャ

### 主要コンポーネント

#### 1. LocaleConfiguration
- **役割**: 外部設定の管理とキャッシュ
- **場所**: `app/lib/locale_configuration.rb`
- **機能**: YAMLファイルから設定を読み込み、1時間キャッシュ

#### 2. LocaleService
- **役割**: ロケール決定とリダイレクト処理
- **場所**: `app/services/locale_service.rb`
- **機能**: ユーザー設定、ブラウザ設定、デフォルト値の優先順位処理

#### 3. LocaleValidator
- **役割**: ロケールの検証
- **場所**: `app/lib/locale_validator.rb`
- **機能**: 利用可能ロケールとの照合

#### 4. LocaleHelper
- **役割**: URL操作とパス変換
- **場所**: `app/helpers/locale_helper.rb`
- **機能**: パスベースロケール処理

#### 5. LocaleUrlHelper
- **役割**: URL生成とリンク作成
- **場所**: `app/helpers/locale_url_helper.rb`
- **機能**: 統一されたURL生成

## URL戦略

### パスベース統一戦略
```
/ja/users      # 日本語ユーザーページ
/en/users      # 英語ユーザーページ
/ja/           # 日本語ホーム
/en/           # 英語ホーム
```

### 明示的ロケール必須化
- 全てのURLにロケールプレフィックス必須
- OAuth認証コールバックは例外扱い
- ルートパス `/` は適切なロケール付きURLへリダイレクト

## ロケール決定優先順位

### 1. 通常処理
1. 明示的引数（メソッド呼び出し時）
2. URLパスのロケール（`:locale`パラメータ）
3. フォールバック処理

### 2. フォールバック処理
1. ユーザー設定（`user.preferred_language`）
2. ブラウザ設定（`Accept-Language`ヘッダー）
3. デフォルトロケール（`config/locales.yml`）

### 3. OAuth特別処理
1. OAuth認証パラメータ
2. セッション保存されたロケール
3. 通常のフォールバック処理

## 設定

### config/locales.yml
```yaml
# ロケール設定
default_locale: :en
available_locales:
  - :en
  - :ja

# ロケール表示名
locale_names:
  en: "English"
  ja: "日本語"

# ネイティブ名
locale_native_names:
  en: "English"
  ja: "日本語"

# キャッシュ設定
cache_ttl: 3600 # 1時間
```

## 使用方法

### コントローラーでのロケール設定
```ruby
class ApplicationController < ActionController::Base
  before_action :set_locale

  private

  def set_locale
    locale_service.set_locale
  end

  def locale_service
    @locale_service ||= LocaleService.new(self)
  end
end
```

### 言語切り替えリンク
```erb
<%= link_to "English", locale_url_for(:en), class: "language-switch" %>
<%= link_to "日本語", locale_url_for(:ja), class: "language-switch" %>
```

### OAuth認証での言語保持
```ruby
# OAuth認証開始時
def store_oauth_locale
  session[:oauth_locale] = {
    locale: params[:locale] || I18n.locale.to_s,
    stored_at: Time.current
  }
end

# OAuth認証完了時
def determine_oauth_locale
  oauth_locale_service.determine_oauth_locale
end
```

## テスト

### テストカバレッジ
- `spec/services/locale_service_spec.rb` - ロケール決定ロジック
- `spec/helpers/locale_helper_spec.rb` - URL操作
- `spec/helpers/locale_url_helper_spec.rb` - URL生成
- `spec/lib/locale_validator_spec.rb` - ロケール検証
- `spec/system/oauth_locale_spec.rb` - OAuth言語引き継ぎ
- `spec/requests/locale_controller_spec.rb` - ルーティング

### テスト実行
```bash
# 全てのロケール関連テスト
bundle exec rspec spec/ -t locale

# 特定のテストファイル
bundle exec rspec spec/services/locale_service_spec.rb
```

## リファクタリング履歴

このシステムは2025年6月に大幅なリファクタリングを実施しました：

1. **設定の外部化とキャッシュ機能の追加**
2. **URL戦略変更の準備**
3. **ルーティング構造の修正（明示的ロケール必須化）**
4. **LocaleServiceロジックの簡素化**
5. **UI/UX一貫性の改善 + OAuth改善**
6. **クリーンアップと最適化**

詳細は `docs/LOCALE_REFACTORING_MASTER_PLAN.md` を参照してください。
