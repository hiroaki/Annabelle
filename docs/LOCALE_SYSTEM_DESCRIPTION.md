(NOTE: このファイルの内容は GPT-4.1 にて自動生成したものです)

# Annabelle ロケールシステム現状説明（2025年版）

## 1. システム全体像
Annabelleのロケールシステムは、利用可能な言語（ロケール）を外部設定ファイルで一元管理し、ユーザーやリクエストごとに最適なロケールを決定・適用する仕組みです。I18nの標準機能を活用しつつ、独自のロケール判定・URL制御・バリデーションを実装しています。

## 2. ロケール設定の外部化と管理
- 設定ファイル `config/locales.yml` にて、利用可能なロケール（`available`）、デフォルトロケール（`default`）、各ロケールのメタデータ（表示名・ネイティブ名・方向性）を管理。
- `LocaleConfiguration` クラス（`app/lib/locale_configuration.rb`）がこの設定を読み込み、APIとして提供。
- 設定はアプリ起動時に一度だけ読み込まれます。（キャッシュや自動リロード等の複雑な仕組みは提供していません。）

## 3. ロケール決定の流れ
- `LocaleService`（`app/services/locale_service.rb`）がロケール決定の中心的役割を担う。
- 決定ロジックは以下の優先順位で判定：
  1. ユーザーの明示的な選択（パラメータやセッション）
  2. ログインユーザーの設定（`preferred_language`）
  3. ブラウザのAccept-Languageヘッダー
  4. デフォルトロケール
- 決定したロケールは `I18n.locale` にセットされ、以降のリクエスト処理に反映。

## 4. URL・パスのロケール制御
- すべての主要なパスは `/ja/xxx` のようにロケールプレフィックス付きで生成。
- `LocaleHelper` でパスからロケール部分の除去・付与を一貫して実装。
- ロケール切替時は、現在のパスをロケール付きでリダイレクトすることでUXを維持。
- `LocaleController`/`LocaleRedirectController` がロケール切替・自動リダイレクトを担当。

## 5. バリデーションと拡張性
- `LocaleValidator`（`app/lib/locale_validator.rb`）でロケール値の妥当性を検証。
- 利用可能ロケールは `LocaleConfiguration` から取得し、将来的な追加・削除も柔軟に対応。
- メタデータ（表示名・ネイティブ名）は設定ファイルで管理し、UI多言語化にも対応。

## 6. 主要クラス・モジュールの役割
- `LocaleConfiguration`：ロケール設定の読み込み・API化
- `LocaleService`：リクエストごとのロケール決定ロジック
- `LocaleHelper`：パス・URLのロケール制御（統合済み）
- `LocalePathUtils`：パス操作の純粋関数（新規）
- `LocaleValidator`：ロケール値のバリデーション
- `LocaleController`/`LocaleRedirectController`：ロケール切替・リダイレクト処理

---

本ドキュメントは2025年6月時点のAnnabelleロケールシステムの実装現状をまとめたものです。
