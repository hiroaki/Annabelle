# LocalePathUtils モジュール化・mix-in 改修プラン

## 目的
- ロケール付きパス/URLの生成・除去などのコアロジックを一箇所（モジュール）に集約し、
  ヘルパーやサービス層で mix-in して再利用性・保守性を高める。

## 改修方針

### 1. コアロジックのモジュール化
- `app/lib/locale_path_utils.rb` などに新規モジュール `LocalePathUtils` を作成
- 以下のような純粋関数を集約：
  - `add_locale_prefix(path, locale)`
  - `remove_locale_prefix(path)`
  - `current_path_with_locale(path, locale)`
  - 必要に応じて他のパス操作系も

### 2. 既存ヘルパー・サービスの整理
- `LocaleHelper`・`LocaleUrlHelper`・`LocaleService` から、
  上記のパス操作ロジックを `LocalePathUtils` へ移動
- 各クラス/モジュールで `include LocalePathUtils` し、
  コアロジックを呼び出す形に変更

### 3. ヘルパーの統合
- `LocaleHelper` と `LocaleUrlHelper` は統合し、
  ロケール関連のパス・URL操作を一元的に扱う `LocaleHelper` とする
- 統合により重複排除・認知負荷軽減・保守性向上を図る

### 4. 責務の明確化
- `LocalePathUtils`：パス/URLの純粋な変換・生成のみ担当
- `LocaleHelper`（統合後）：ビュー/コントローラ補助やUI向けのラッパー
- `LocaleService`：文脈依存のロケール決定・リダイレクト先決定

### 5. テスト
- `LocalePathUtils` 単体のユニットテストを追加
- 既存のヘルパー・サービスのテストも通ることを確認

## 想定ファイル構成
- `app/lib/locale_path_utils.rb`（新規）
- `app/helpers/locale_helper.rb`（統合・mix-in化）
- `app/services/locale_service.rb`（mix-in化）

## メリット
- コアロジックの一元管理による保守性向上
- 各層での再利用性向上
- ヘルパー統合による重複排除・認知負荷軽減
- テスト容易性の向上

---

## 🎉 実装完了の成果

### ✅ **達成されたメリット**

1. **コードの一元管理**
   - パス操作のコアロジックが`LocalePathUtils`に集約
   - 重複コードの完全な排除

2. **再利用性の向上**
   - `LocaleHelper`、`LocaleService`で共通ロジックを再利用
   - 将来的な拡張も容易

3. **コードの簡潔性**
   - 不要な後方互換性ラッパーを削除
   - よりシンプルで理解しやすい構造

4. **テスト容易性**
   - `LocalePathUtils`の純粋関数として単体テスト可能
   - 各層のテストも維持

4. **保守性の向上**
   - 責務の明確な分離
   - ロジック変更時の影響範囲が明確

4. **保守性の向上**
   - 責務の明確な分離
   - ロジック変更時の影響範囲が明確

5. **シンプルな構造**
   - 不要なラッパークラスを削除
   - より直感的なAPI設計

### 📊 **改修前後の比較**

| 項目 | 改修前 | 改修後 |
|------|--------|--------|
| パス操作ロジック | 2つのヘルパーに分散 | 1つのモジュールに集約 |
| ヘルパーファイル数 | 2つ (`LocaleHelper`, `LocaleUrlHelper`) | 1つ (`LocaleHelper`) |
| コード重複 | あり | なし |
| テスト | 分散 | 集約+統合 |
| 将来の拡張性 | 困難 | 容易 |

---

## 今後の推奨事項

1. **新しいパス操作が必要な場合**
   - `LocalePathUtils`に追加することを検討
   
2. **パフォーマンス監視**
   - Mix-inによる若干のオーバーヘッドに注意

3. **将来的な拡張**
   - 新しいロケール機能は統合された`LocaleHelper`に追加

