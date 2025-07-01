(NOTE: このファイルは、ロケールシステムの実装現状を GPT-4.1 に指示してまとめさせたものです)

# Annabelle ロケールシステム設計・実装ガイド

## 1. 概要
Annabelleのロケール（多言語）システムは、明示的なURLプレフィックス（例: `/ja/`, `/en/`）によるルーティングを基本とし、ユーザーやリクエストごとに最適なロケール判定・切替を行う仕組みです。
この設計により、アプリケーション全体で一貫した多言語対応と、柔軟な拡張性・保守性を実現しています。

---

## 2. ロケール設計と動作の原則

- **ロケール付きURLの原則**
  主要な画面やAPIは `/ja/...` や `/en/...` のようなロケールスコープ付きURLで提供されます。
  これにより、URL自体が現在の言語状態を明示し、SEOやブックマーク、外部連携にも強い構造となります。

  ```
  # ロケール付きURLの例
  /ja                           # 日本語トップページ（messages#index）
  /en                           # 英語トップページ（messages#index）
  /ja/messages                  # 日本語メッセージ一覧
  /en/messages                  # 英語メッセージ一覧
  /ja/dashboard                 # 日本語ダッシュボード
  /en/dashboard                 # 英語ダッシュボード
  /ja/profile/edit              # 日本語プロフィール編集
  /en/profile/edit              # 英語プロフィール編集
  ```

- **例外パス（ロケール管理の適用外パス）**
  OAuth認証コールバックや一部の外部サービス連携用エンドポイントなど、ロケールスコープ外で動作するパスが存在します。
  これらのパスはAnnabelleのロケール管理（ロケール自動判定・リダイレクト・ロケール付き404処理など）の適用範囲外であり、通常のRailsルーティングやコントローラで個別に処理されます。

  ```
  # 例外パスの例
  /users/auth/github/callback   # GitHub OAuth コールバック
  /users/auth/failure           # OAuth 認証失敗
  /up                           # ヘルスチェック
  ```

- **ルートアクセス時の自動ロケール判定とリダイレクト**
  `/`（ルート）へのアクセス時は、LocaleUtilsのロジックにより「パラメータ → ユーザー設定 → Accept-Languageヘッダ → デフォルト」の順でロケールを決定し、該当ロケールのトップページ（例: `/ja` または `/en`）へリダイレクトします。

  ```
  # リダイレクトの例
  GET /                           → リダイレクト → GET /ja （日本語ユーザーの場合）
  GET /?locale=en                 → リダイレクト → GET /en （パラメータ指定）
  GET / (Accept-Language: en-US)  → リダイレクト → GET /en （ヘッダ判定）
  ```

- **専用エンドポイントによるロケール切替**
  `/locale/:locale` へのアクセスで、指定ロケールが有効な場合は `redirect_to`パラメータで指定されたパス、またはロケールトップへリダイレクトします。

  ```
  # ロケール切替の例
  GET /locale/ja                                   → リダイレクト → GET /ja
  GET /locale/en?redirect_to=/en/dashboard         → リダイレクト → GET /en/dashboard
  GET /locale/ja?redirect_to=/ja/messages          → リダイレクト → GET /ja/messages
  GET /locale/invalid                              → リダイレクト → GET / （アラート表示）
  ```

- **スコープ内での言語切替**
  ロケールスコープ内では、言語切替UIやURL操作ヘルパを通じて、現在のページのまま他言語の同一パスへ遷移できます。

  ```
  現在のページ: /en/dashboard
  ↓ 日本語切替リンクをクリック
  遷移先: /ja/dashboard
  ```

- **共通エラーハンドリング**
  サポートされていないロケールが指定された場合は、ルートへリダイレクトし、必要に応じてアラートを表示します（この挙動は全体共通です）。

  ```
  # エラーハンドリングの例
  GET /fr/messages                → 404 Not Found （フランス語は未サポート）
  GET /locale/fr                  → リダイレクト → GET / （アラート表示）
  ```

---

## 3. 主要コンポーネントと責務

- **LocaleController**
  ルートアクセス時の自動リダイレクト、明示的なロケール切替（`/locale/:locale`）、不正ロケール時のエラーハンドリングを担当。

- **LocaleUtils**
  ロケール決定ロジックを提供。判定優先順位は「パラメータ → ユーザー設定 → Accept-Languageヘッダ → デフォルト」。

- **LocaleValidator**
  サポート対象ロケールかどうかのバリデーションを一元化。

- **LocaleHelper**
  パスからのロケール抽出・付与・除去、OAuth用パラメータ生成など、URL操作や補助的な処理を提供。

- **LocaleConfiguration**
  `config/locales.yml`から利用可能ロケール・デフォルトロケール・メタデータを読み込み、APIとして提供。

---

## 4. 設定ファイル（config/locales.yml）の構成と役割

Annabelleのロケール設定は `config/locales.yml` で一元管理されています。

```yaml
locales:
  default: en
  available:
    - en
    - ja
  metadata:
    en:
      name: "English"
      native_name: "English"
      direction: ltr
    ja:
      name: "Japanese"
      native_name: "日本語"
      direction: ltr
```

- **default**
  デフォルトロケール。ルートアクセス時や判定不能時に使用されます。

- **available**
  利用可能なロケールのリスト。ここに記載されたロケールのみが有効です。

- **metadata**
  各ロケールの表示名（`name`）、ネイティブ名（`native_name`）、テキスト方向（`direction`）などのメタデータ。
  これらはUI表示や言語切替UIの生成などに利用されます。
  - `direction`はテキストの表示方向（`ltr`=左→右, `rtl`=右→左）を示します。

