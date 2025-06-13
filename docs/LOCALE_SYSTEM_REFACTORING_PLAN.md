# ロケールシステム改修計画

**作成日:** 2025年6月12日  
**目的:** 現在のロケールシステムの懸念点を解決し、より保守しやすく一貫性のあるシステムに改修する

## 📋 改修前の懸念点

### 🚨 主要な問題点

1. **省略可能なロケールの問題**
   - デフォルトロケール（英語）が `/` と `/en/` の両方でアクセス可能
   - SEO上の重複コンテンツ問題
   - URLの一貫性の欠如

2. **URLストラテジーの混在**
   - パスベース (`/ja/users`) と クエリパラメータベース (`?lang=ja`) が併存
   - ユーザーの混乱を招く
   - 実装の複雑性増大

3. **設定のハードコード**
   - `scope "(:locale)", locale: /en|ja/` でロケールが硬コード
   - 新しいロケール追加時に複数箇所の修正が必要
   - 保守性の低下

4. **複雑な条件分岐**
   - `LocaleService#determine_effective_locale` の判定ロジックが複雑
   - リダイレクトループのリスク
   - デバッグの困難さ

5. **ApplicationControllerの過度な責任**
   ```ruby
   def default_url_options
     { locale: I18n.locale }
   ```
   - 全URLに自動的にロケールが付与される
   - 外部リンクやAPI レスポンスにも影響

6. **テスト環境と本番環境の差異**
   - テスト環境では英語でも `/en/` プレフィックスが付く
   - 環境間での挙動の不一致

---

## 🎯 改修の目標

1. **省略可能なロケールの廃止** - 全ロケールを明示的にURLに含める
2. **URLストラテジーの統一** - パスベースに一本化、クエリパラメータ廃止
3. **設定の外部化** - ハードコードされた制約の解消
4. **複雑性の軽減** - 条件分岐とリダイレクト処理の簡素化
5. **一貫性の向上** - 全環境での統一した挙動
6. **保守性の改善** - 新ロケール追加の容易化

---

## 📊 改修ステップ

### **Step 1: 設定の外部化と基盤整備** 🔧

**解決する懸念点:**
- 設定のハードコード問題
- 新しいロケール追加時の複数箇所修正の必要性
- LocaleValidatorのパフォーマンス問題

**目的:** ハードコードされた設定を外部化し、改修の基盤を作る

**作業内容:**
1. **ロケール設定の外部化**
   ```yaml
   # config/locales_config.yml
   default_locale: en
   available_locales:
     - en
     - ja
   locale_names:
     en: "English"
     ja: "日本語"
   ```

2. **LocaleValidator のキャッシュ機能追加**
   ```ruby
   def self.valid_locale_strings
     @valid_locale_strings ||= I18n.available_locales.map(&:to_s)
   end
   ```

3. **ルート制約を動的生成に変更**
   ```ruby
   # config/routes.rb
   locale_constraint = LocaleConfig.available_locales.join('|')
   scope "(:locale)", locale: /#{locale_constraint}/ do
   ```

4. **設定読み込み用のヘルパークラス作成**
   ```ruby
   # app/lib/locale_config.rb
   class LocaleConfig
     def self.available_locales
       @available_locales ||= Rails.application.config_for(:locales_config)['available_locales']
     end
   end
   ```

**成功条件:**
- 既存のテストが全て通る
- 新しいロケール追加が設定ファイルのみで可能
- パフォーマンスが向上（キャッシュ効果）

**検証ポイント:**
- [ ] 全テストの通過
- [ ] 既存機能の動作確認
- [ ] 新ロケール追加のテスト
- [ ] パフォーマンス測定

---

### **Step 2: URLストラテジー変更の準備** 🚧

**解決する懸念点:**
- URLストラテジーの混在問題
- ApplicationControllerの過度な責任
- テスト環境と本番環境の差異

**目的:** 新しいURL構造への移行準備とヘルパーメソッド整備

**作業内容:**
1. **新しいURL生成ヘルパーの追加**
   ```ruby
   # app/helpers/new_locale_helper.rb (一時的)
   module NewLocaleHelper
     def explicit_locale_path(path, locale)
       "/#{locale}#{path}"
     end
   end
   ```

2. **ApplicationController#default_url_options の条件分岐追加**
   ```ruby
   def default_url_options
     if Rails.env.test? || ENV['USE_EXPLICIT_LOCALES'] == 'true'
       { locale: I18n.locale }
     else
       {}
     end
   end
   ```

3. **フィーチャーフラグの導入**
   ```ruby
   # config/application.rb
   config.x.explicit_locales = ENV.fetch('USE_EXPLICIT_LOCALES', 'false') == 'true'
   ```

4. **並行テストの実装**
   - 新旧両方のURL構造でのテスト実行
   - システムテストでの動作確認

**成功条件:**
- 新旧両方のURL構造が並行稼働
- 既存機能に影響なし
- フィーチャーフラグによる切り替えが可能

**検証ポイント:**
- [ ] 新URL構造での基本動作確認
- [ ] 既存URL構造の維持確認
- [ ] フィーチャーフラグの動作確認
- [ ] 全テストの通過

---

### **Step 3: ルーティング構造の変更** 🛣️

**解決する懸念点:**
- 省略可能なロケールの問題
- SEO上の重複コンテンツ問題
- URLの一貫性の欠如

**目的:** 省略可能なロケールを廃止し、全ロケールを明示的に

**作業内容:**
1. **ルート制約を必須に変更**
   ```ruby
   # 変更前: scope "(:locale)", locale: /en|ja/
   # 変更後: scope ":locale", locale: /#{locale_constraint}/
   ```

2. **ルートルートの明示的な処理**
   ```ruby
   # config/routes.rb
   root to: redirect("/#{I18n.default_locale}")
   
   scope ":locale", locale: /#{locale_constraint}/ do
     # 既存のルート定義
     root 'messages#index'
   end
   ```

3. **リダイレクト処理の追加**
   ```ruby
   # app/controllers/application_controller.rb
   before_action :ensure_locale_in_url
   
   private
   
   def ensure_locale_in_url
     unless params[:locale].present?
       redirect_to "/#{determine_redirect_locale}#{request.path}"
     end
   end
   ```

4. **既存のロケール処理の更新**
   - `LocaleHelper` の更新
   - `LocaleService` の更新
   - ビューでのURLヘルパー使用箇所の更新

**成功条件:**
- `/` へのアクセスが `/en` に適切にリダイレクト
- 全てのパスで明示的なロケールが必須
- SEO上の重複コンテンツ問題が解消
- 既存の全機能が新URL構造で動作

**検証ポイント:**
- [ ] ルートパスのリダイレクト確認
- [ ] 全ページでのロケール明示確認
- [ ] SEOクローラーでの重複確認
- [ ] 全システムテストの通過

⚠️ **注意: このステップは最も影響が大きいため、十分なテストと段階的な適用が必要**

---

### **Step 4: LocaleServiceの簡素化** ⚡

**解決する懸念点:**
- 複雑な条件分岐
- リダイレクトループのリスク
- URLストラテジーの混在（クエリパラメータ処理）

**目的:** 複雑な条件分岐を整理し、クエリパラメータ処理を削除

**作業内容:**
1. **`determine_effective_locale` の優先順位簡素化**
   ```ruby
   def determine_effective_locale(locale = nil)
     # 1. 明示的なパラメータ
     return locale.to_s if LocaleValidator.valid_locale?(locale)
     
     # 2. URLパスロケール（必須になったため常に存在）
     url_locale = params[:locale]
     return url_locale.to_s if LocaleValidator.valid_locale?(url_locale)
     
     # 3. フォールバック（リダイレクト時のみ使用）
     determine_fallback_locale
   end
   ```

2. **クエリパラメータ処理の削除**
   - `LocaleHelper.current_path_with_locale` の簡素化
   - `?lang=` パラメータ処理の除去
   - `LocaleController` の簡素化または削除

3. **リダイレクト処理の簡素化**
   ```ruby
   def determine_fallback_locale
     # ユーザー設定 → ブラウザ設定 → デフォルト
     extract_from_user(current_user) ||
       extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE']) ||
       I18n.default_locale.to_s
   end
   ```

4. **不要なメソッドの削除**
   - クエリパラメータ関連の処理
   - 複雑な条件分岐処理

**成功条件:**
- ロケール決定ロジックが単純になる
- パフォーマンスが向上
- リダイレクトループのリスクが削減
- コードの可読性が向上

**検証ポイント:**
- [ ] 新しいロケール決定ロジックの動作確認
- [ ] パフォーマンス測定
- [ ] エッジケースでのリダイレクト確認
- [ ] 全テストの通過

---

### **Step 5: UI/UXの改善** 🎨

**解決する懸念点:**
- ユーザーの混乱（URLとクエリパラメータの混在）
- 言語切り替えの一貫性の欠如
- ユーザー体験の向上

**目的:** 言語切り替えUIの一貫性向上とユーザー体験の改善

**作業内容:**
1. **言語切り替えリンクの改善**
   ```erb
   <!-- app/views/shared/_language_switcher.html.erb -->
   <div class="language-switcher">
     <% LocaleConfig.available_locales.each do |locale| %>
       <%= link_to_unless_current LocaleConfig.locale_name(locale),
           url_for(locale: locale),
           class: "hover:text-slate-600 #{I18n.locale == locale ? 'font-bold' : ''}" %>
     <% end %>
   </div>
   ```

2. **LocaleController の再設計または削除**
   - クエリパラメータ処理が不要になるため、シンプルなリダイレクト処理に変更
   - または完全に削除してURL直接アクセスに統一

3. **ログアウト後の言語保持ロジック簡素化**
   ```ruby
   def after_sign_out_path_for(resource_or_scope)
     # ユーザー設定 → デフォルトロケール
     locale = determine_logout_locale || I18n.default_locale
     root_path(locale: locale)
   end
   ```

4. **フォーム送信後のリダイレクト改善**
   - ユーザー設定変更後の適切なロケールURLへのリダイレクト
   - 一貫性のあるURL生成

**成功条件:**
- 言語切り替えが直感的
- ユーザー設定とURL表示が一致
- ログアウト/ログイン体験の改善
- 全ての画面遷移でロケールが適切に保持

**検証ポイント:**
- [ ] 言語切り替えの動作確認
- [ ] ログアウト/ログイン体験の確認
- [ ] フォーム送信後の挙動確認
- [ ] 全システムテストの通過

---

### **Step 6: クリーンアップと最適化** 🧹

**解決する懸念点:**
- コードの複雑性
- 不要なコードの残存
- ドキュメントの更新不足

**目的:** 不要なコードの削除と最終的な最適化

**作業内容:**
1. **旧コードの削除**
   - クエリパラメータ関連の処理
   - 省略可能なロケール関連の処理
   - 使用されなくなったヘルパーメソッド
   - 一時的に作成したフィーチャーフラグ

2. **CustomFailureApp の簡素化**
   ```ruby
   class CustomFailureApp < Devise::FailureApp
     def redirect_url
       # シンプルなロケール付きURL生成
       url = super
       # 必要に応じてロケール情報を付与
     end
   end
   ```

3. **テストの整理と更新**
   - 不要になったテストケースの削除
   - 新しいURL構造に対応したテストケースの追加
   - システムテストの更新

4. **ドキュメントの更新**
   - `LOCALE_SYSTEM.md` の全面更新
   - 新しいアーキテクチャの説明
   - 開発者向けガイドラインの更新
   - READMEの更新

5. **パフォーマンス最適化**
   - 不要な処理の削除による高速化
   - キャッシュ機能の活用
   - メモリ使用量の最適化

**成功条件:**
- コードベースがクリーンになる
- パフォーマンスが向上
- 保守性が向上
- ドキュメントが最新状態

**検証ポイント:**
- [ ] 全不要コードの削除確認
- [ ] パフォーマンス測定
- [ ] ドキュメントの正確性確認
- [ ] 最終的な全テスト実行

---

## 🔄 各ステップでの共通検証項目

### 必須チェックリスト
- [ ] 全テストの通過（RSpec, システムテスト）
- [ ] 既存機能の動作確認
- [ ] パフォーマンスの測定と比較
- [ ] ブラウザでの手動動作確認
- [ ] 異なるロケールでの動作確認
- [ ] ログアウト/ログイン体験の確認

### コード品質チェック
- [ ] Rubocop による静的解析
- [ ] コードレビューの実施
- [ ] セキュリティチェック
- [ ] 可読性の確認

---

## 🚨 リスク管理

### 高リスク箇所の特定
1. **Step 3 (ルーティング変更)** - 最も影響が大きく、慎重な実施が必要
2. **Step 4 (LocaleService変更)** - ビジネスロジックの核心部分
3. **Step 5 (UI/UX改善)** - ユーザー体験に直接影響

### リスク軽減策
- **段階的適用**: フィーチャーフラグによる段階的な機能有効化
- **十分なテスト**: 各ステップでの包括的なテスト実行
- **ロールバック準備**: 各ステップでの戻し手順の準備
- **ステージング検証**: 本番適用前のステージング環境での十分な検証
- **監視強化**: 本番適用時のメトリクス監視

### 緊急時対応
- 各ステップでのコミットタグ作成
- ロールバック手順書の準備
- 障害時の連絡体制確立

---

## 📅 推奨実施スケジュール

| 期間 | ステップ | リスクレベル | 主要作業 |
|------|----------|--------------|----------|
| Week 1 | Step 1 | 🟢 低 | 設定外部化 |
| Week 2 | Step 2 | 🟡 中 | 移行準備 |
| Week 3 | Step 3 | 🔴 高 | ルーティング変更 |
| Week 4 | Step 4 | 🟡 中 | LocaleService簡素化 |
| Week 5 | Step 5 | 🟡 中 | UI/UX改善 |
| Week 6 | Step 6 | 🟢 低 | クリーンアップ |

---

## 📝 備考

### 参考リソース
- 現在のドキュメント: `docs/LOCALE_SYSTEM.md`
- 関連ファイル:
  - `app/services/locale_service.rb`
  - `app/helpers/locale_helper.rb`
  - `app/controllers/locale_controller.rb`
  - `config/routes.rb`

### 関係者への連絡
- 各ステップ完了時にレビューを実施
- UI/UX変更時はデザイナーとの連携
- 本番適用時は運用チームとの調整

---

**最終更新:** 2025年6月12日  
**次回レビュー予定:** 各ステップ完了時

このドキュメントは改修の進行に合わせて更新していきます。質問や懸念事項があれば、随時相談してください。
