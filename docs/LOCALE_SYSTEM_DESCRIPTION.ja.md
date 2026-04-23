[English version is here](LOCALE_SYSTEM_DESCRIPTION.md)

# Annabelle ロケールシステム設計・実装ガイド

## 1. 概要
Annabelle のロケール（多言語）システムは、明示的な URL プレフィックス（例: `/ja/`, `/en/`）によるルーティングを基本とし、ユーザーやリクエストごとに最適なロケール判定・切替を行う仕組みです。
この設計により、アプリケーション全体で一貫した多言語対応と、柔軟な拡張性・保守性を実現しています。

---

## 2. ロケール設計と動作の原則

- **ロケール付き URL の原則**
  主要な画面や API は `/ja/...` や `/en/...` のようなロケールスコープ付き URL で提供されます。
  これにより、URL 自体が現在の言語状態を明示し、SEO やブックマーク、外部連携にも強い構造となります。

  ```
  # ロケール付き URL の例
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
  OAuth 認証コールバックや一部の外部サービス連携用エンドポイントなど、ロケールスコープ外で動作するパスが存在します。
  これらのパスは Annabelle のロケール管理（ロケール自動判定、リダイレクト、ロケール付き 404 処理など）の適用範囲外であり、通常の Rails ルーティングやコントローラで個別に処理されます。

  ```
  # 例外パスの例
  /users/auth/github/callback   # GitHub OAuth コールバック
  /users/auth/failure           # OAuth 認証失敗
  /up                           # ヘルスチェック
  ```

- **ルートアクセス時の自動ロケール判定とリダイレクト**
  `/` へのアクセス時は、LocaleUtils のロジックにより「パラメータ -> ユーザー設定 -> Accept-Language ヘッダ -> デフォルト」の順でロケールを決定し、該当ロケールのトップページ（例: `/ja` または `/en`）へリダイレクトします。

  ```
  # リダイレクトの例
  GET /                           -> リダイレクト -> GET /ja
  GET /?locale=en                 -> リダイレクト -> GET /en
  GET / (Accept-Language: en-US)  -> リダイレクト -> GET /en
  ```

- **専用エンドポイントによるロケール切替**
  `/locale/:locale` へのアクセスで、指定ロケールが有効な場合は `redirect_to` パラメータで指定されたパス、またはロケールトップへリダイレクトします。

  ```
  # ロケール切替の例
  GET /locale/ja                                   -> リダイレクト -> GET /ja
  GET /locale/en?redirect_to=/en/dashboard         -> リダイレクト -> GET /en/dashboard
  GET /locale/ja?redirect_to=/ja/messages          -> リダイレクト -> GET /ja/messages
  GET /locale/invalid                              -> リダイレクト -> GET / （アラート表示）
  ```

- **スコープ内での言語切替**
  ロケールスコープ内では、言語切替 UI や URL 操作ヘルパを通じて、現在のページのまま他言語の同一パスへ遷移できます。

  ```
  現在のページ: /en/dashboard
  -> 日本語切替リンクをクリック
  遷移先: /ja/dashboard
  ```

- **共通エラーハンドリング**
  サポートされていないロケールが指定された場合は、ルートへリダイレクトし、必要に応じてアラートを表示します。この挙動は全体で共通です。

  ```
  # エラーハンドリングの例
  GET /fr/messages                -> 404 Not Found
  GET /locale/fr                  -> リダイレクト -> GET / （アラート表示）
  ```

---

## 3. 主要コンポーネントと責務

- **LocaleController**
  ルートアクセス時の自動リダイレクト、明示的なロケール切替（`/locale/:locale`）、不正ロケール時のエラーハンドリングを担当します。

- **LocaleUtils**
  ロケール決定ロジックを提供します。判定優先順位は「パラメータ -> ユーザー設定 -> Accept-Language ヘッダ -> デフォルト」です。

- **LocaleValidator**
  サポート対象ロケールかどうかのバリデーションを一元化します。

- **LocaleHelper**
  パスからのロケール抽出、付与、除去、OAuth 用パラメータ生成など、URL 操作や補助的な処理を提供します。

- **LocaleConfiguration**
  `config/locales.yml` から利用可能ロケール、デフォルトロケール、メタデータを読み込み、API として提供します。

---

## 4. 設定ファイル `config/locales.yml` の構成と役割

Annabelle のロケール設定は `config/locales.yml` で一元管理されています。

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
  デフォルトロケールです。ルートアクセス時や判定不能時に使用されます。

- **available**
  利用可能なロケールの一覧です。ここに記載されたロケールのみが有効です。

- **metadata**
  各ロケールの表示名（`name`）、ネイティブ名（`native_name`）、テキスト方向（`direction`）などのメタデータです。
  これらは UI 表示や言語切替 UI の生成などに利用されます。
  `direction` はテキストの表示方向を示し、`ltr` は左から右、`rtl` は右から左を意味します。