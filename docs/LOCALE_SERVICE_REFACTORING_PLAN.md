# LocaleService リファクタリング計画

## 背景

現在のロケールサービスは以下の構造になっている：

- `LocaleService`（スーパークラス）: 一般的なロケール決定処理
- `OAuthLocaleService`（サブクラス）: OAuth認証時の特殊なロケール決定処理

## 現状の問題点

### 1. 戻り値形式の不統一
- **スーパークラス**: `"ja"` (文字列) を返す
- **サブクラス**: `{locale: "ja", source: "user_preference"}` (ハッシュ) を返す

### 2. コードの重複
- `extract_from_user` と `extract_from_header` でロジックが重複
- サブクラスでは主にsource情報を追加するだけのラッパー

### 3. OAuth固有処理の分析

#### OAuth固有で真に必要な部分
- `extract_from_omniauth_params`: OAuth パラメータ処理
- `extract_from_session`: **@oauth_controller への依存（唯一の真の固有処理）**

#### 汎用化可能な部分
- `extract_from_user`: source情報追加のみ
- `extract_from_header`: source情報追加のみ
- `default_locale`: source情報追加のみ

## 提案する改善案

### 1. スーパークラスの拡張
```ruby
class LocaleService
  # 戻り値を [locale, source] の配列に統一
  def extract_from_user(user)
    return [nil, nil] unless user&.preferred_language.present?

    locale = user.preferred_language
    if LocaleValidator.valid_locale?(locale)
      [locale, "user_preference"]
    else
      [nil, nil]
    end
  end

  def extract_from_header(header)
    # 既存のロケール決定ロジック
    locale = # ... 既存処理 ...

    if locale
      [locale, "browser_header"]
    else
      [nil, nil]
    end
  end

  def determine_fallback_locale_with_source
    # 複数の戻り値を適切に処理
    locale, source = extract_from_user(current_user)
    return [locale, source] if locale

    locale, source = extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
    return [locale, source] if locale

    [LocaleConfiguration.default_locale.to_s, "default"]
  end
end
```

### 2. サブクラスの簡素化
```ruby
class OAuthLocaleService < LocaleService
  # OAuth固有のメソッドを追加
  def extract_from_omniauth_params
    omniauth_params = request.env["omniauth.params"] || {}
    oauth_locale = omniauth_params["lang"] || omniauth_params["locale"]

    if oauth_locale.present? && LocaleValidator.valid_locale?(oauth_locale)
      [oauth_locale, "omniauth_params"]
    else
      [nil, nil]
    end
  end

  # 唯一の真のオーバーライド - @oauth_controller依存
  def extract_from_session
    session_data = @oauth_controller.send(:restore_oauth_locale_from_session)
    return [nil, nil] unless session_data

    locale = session_data.is_a?(Hash) ? session_data[:locale] : session_data
    locale ? [locale, "session"] : [nil, nil]
  end

  def determine_oauth_locale
    # OAuth特有の優先順位でフォールバック
    locale, source = extract_from_omniauth_params
    return [locale, source] if locale

    locale, source = extract_from_session
    return [locale, source] if locale

    # 以下はスーパークラスの拡張メソッドを利用
    locale, source = extract_from_user(current_user)
    return [locale, source] if locale

    locale, source = extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
    return [locale, source] if locale

    [I18n.default_locale.to_s, "default"]
  end
end
```

### 3. 呼び出し側の調整
```ruby
# 現在
@oauth_locale_result = oauth_locale_service.determine_oauth_locale
locale = @oauth_locale_result[:locale]
source = @oauth_locale_result[:source]

# 改善後
locale, source = oauth_locale_service.determine_oauth_locale
@oauth_locale_result = { locale: locale, source: source }
```

## 実装方針

### Phase 1: スーパークラスの拡張
1. `LocaleService` に source情報付きメソッドを追加
2. 既存メソッドの後方互換性を維持
3. 新しいメソッドは `_with_source` サフィックスで提供

### Phase 2: サブクラスの簡素化
1. `OAuthLocaleService` を新しいAPIに移行
2. 重複コードを削除
3. OAuth固有処理のみを保持

### Phase 3: 呼び出し側の更新
1. コントローラーでの戻り値処理を調整
2. テストケースの更新

### Phase 4: 後方互換性の段階的削除
1. 旧APIの非推奨警告
2. 将来のバージョンでの削除

## 期待される効果

### 1. コードの簡潔性
- 重複処理の削除
- サブクラスのコード量削減（現在の約60%削減見込み）

### 2. 一貫性の向上
- 戻り値形式の統一
- source情報の標準化

### 3. メンテナンス性の向上
- OAuth固有処理の明確化
- 汎用処理の一元化

### 4. 柔軟性の向上
- source情報の利用/非利用を呼び出し側で選択可能
- 他の認証方式への拡張が容易

## 実装時の注意点

### 1. 後方互換性
- 段階的移行により既存コードへの影響を最小化
- 十分なテストカバレッジの確保

### 2. 戻り値の扱い
- 配列の分割代入 `locale, source = method()` の統一
- nil値の適切な処理

### 3. テストの更新
- 新しい戻り値形式に対応したテストケース
- source情報の検証

## 関連ファイル

- `app/services/locale_service.rb` - 主要なリファクタリング対象
- `app/controllers/users/omniauth_callbacks_controller.rb` - 呼び出し側の調整
- `spec/services/locale_service_spec.rb` - テストの更新が必要
- `spec/requests/omniauth_callbacks_spec.rb` - 統合テストの更新

## 現在の実装状況

2025年6月13日時点：
- 現在のコードは十分に動作し、全テストが通過
- OAuth locale処理の要件は満たされている
- このリファクタリングは品質向上とメンテナンス性向上が目的

## 実装タイミング

このリファクタリングは破壊的変更を含む可能性があるため、以下のタイミングで実施することを推奨：

1. 機能追加の開発が一段落した時期
2. 十分なテスト時間が確保できる時期
3. 他の大きな変更と重複しない時期

---

**作成日**: 2025年6月13日
**最終更新**: 2025年6月13日
**ステータス**: 計画段階
