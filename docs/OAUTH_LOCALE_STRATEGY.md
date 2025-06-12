# OAuth認証時の言語引き継ぎ戦略

## 課題の概要

OAuth認証では外部プロバイダー（GitHub）からのコールバックURLが固定のため、URLにロケール情報を含めることができません。そのため、OAuth認証を開始した時点の言語設定を適切に引き継ぐメカニズムが必要です。

## 現在の実装状況

### 実装済みの仕組み

1. **OAuth開始時のパラメータ保存**
   ```erb
   <!-- app/views/devise/shared/_links.html.erb -->
   oauth_params = {}
   if I18n.locale != I18n.default_locale
     oauth_params[:lang] = I18n.locale.to_s
   elsif params[:lang].present? && LocaleValidator.valid_locale?(params[:lang])
     oauth_params[:lang] = params[:lang]
   end
   ```

2. **コールバック時のロケール復元**
   ```ruby
   # app/controllers/users/omniauth_callbacks_controller.rb
   def store_locale_for_redirect
     omniauth_params = request.env["omniauth.params"] || {}
     locale_param = params[:lang] || params[:locale] ||
                    omniauth_params["lang"] || omniauth_params["locale"]
     @oauth_locale = locale_service.determine_effective_locale(locale_param)
   end
   ```

### 動作フロー

1. ユーザーが日本語ページ（`/ja/users/sign_in`）でOAuth認証開始
2. `oauth_params[:lang] = 'ja'`がOAuthリクエストに含まれる
3. GitHubでの認証後、`/users/auth/github/callback`にリダイレクト
4. `request.env["omniauth.params"]["lang"]`から`'ja'`を取得
5. 日本語でページを表示し、適切なロケール付きURLにリダイレクト

## 改善案

### 1. 状態管理の強化

現在の実装では`omniauth.params`に依存していますが、より確実な状態管理を行います：

```ruby
# OAuth認証開始時にセッションに保存
def store_oauth_locale_in_session
  oauth_locale = determine_current_oauth_locale
  session[:oauth_locale] = oauth_locale if oauth_locale
  session[:oauth_locale_timestamp] = Time.current.to_i
end

# コールバック時にセッションから復元（タイムアウト付き）
def restore_oauth_locale_from_session
  return nil unless session[:oauth_locale_timestamp]
  
  # 10分以内の場合のみ有効
  if Time.current.to_i - session[:oauth_locale_timestamp] < 600
    locale = session.delete(:oauth_locale)
    session.delete(:oauth_locale_timestamp)
    locale if LocaleValidator.valid_locale?(locale)
  else
    session.delete(:oauth_locale)
    session.delete(:oauth_locale_timestamp)
    nil
  end
end
```

### 2. フォールバック戦略の実装

複数の方法を組み合わせて、より確実な言語引き継ぎを実現：

```ruby
def determine_oauth_effective_locale
  # 1. omniauth.paramsから取得（現在の実装）
  omniauth_params = request.env["omniauth.params"] || {}
  locale_from_params = omniauth_params["lang"] || omniauth_params["locale"]
  return locale_from_params if LocaleValidator.valid_locale?(locale_from_params)
  
  # 2. セッションから取得（改善案）
  locale_from_session = restore_oauth_locale_from_session
  return locale_from_session if locale_from_session
  
  # 3. 既存ユーザーの設定言語
  if signed_in_after_oauth? && current_user&.preferred_language.present?
    user_locale = current_user.preferred_language
    return user_locale if LocaleValidator.valid_locale?(user_locale)
  end
  
  # 4. ブラウザの Accept-Language ヘッダー
  locale_from_header = locale_service.extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
  return locale_from_header if locale_from_header
  
  # 5. デフォルトロケール
  I18n.default_locale.to_s
end
```

### 3. リファクタリング計画との整合性

明示的ロケール必須化の計画と整合性を保つため：

```ruby
# OAuth認証後のリダイレクト先決定
def determine_oauth_redirect_path_with_locale
  oauth_locale = determine_oauth_effective_locale
  
  if @is_new_user
    # 新規ユーザーはアカウント設定ページ（ロケール付き）
    if oauth_locale == I18n.default_locale.to_s
      edit_user_registration_path
    else
      edit_user_registration_path(locale: oauth_locale)
    end
  else
    # 既存ユーザーはルートページ（ロケール付き）
    if oauth_locale == I18n.default_locale.to_s
      root_path
    else
      root_path(locale: oauth_locale)
    end
  end
end
```

## 実装の優先順位

### フェーズ1: 現在の実装の強化
1. セッションベースのフォールバック追加
2. ログ出力の改善（デバッグ用）
3. エラーハンドリングの強化

### フェーズ2: リファクタリング計画との統合
1. 明示的ロケール必須化に対応
2. URL生成ロジックの統一
3. テストカバレッジの改善

### フェーズ3: UX改善
1. OAuth認証中の言語表示一貫性
2. エラー時の適切な言語でのメッセージ表示
3. モバイル対応での言語継承

## 実装例

### OAuth開始時（改善版）

```ruby
# app/controllers/concerns/oauth_locale_support.rb
module OauthLocaleSupport
  def prepare_oauth_locale
    current_locale = determine_current_effective_locale
    
    # セッションに保存（フォールバック用）
    session[:oauth_locale] = current_locale
    session[:oauth_locale_timestamp] = Time.current.to_i
    
    # パラメータにも含める（現在の方式）
    { lang: current_locale }
  end
  
  private
  
  def determine_current_effective_locale
    # URLパスのロケール、langパラメータ、現在のI18n.locale等を総合的に判断
    locale_service.determine_effective_locale
  end
end
```

### コールバック時（改善版）

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
def store_locale_for_redirect
  # 複数のソースから最適なロケールを決定
  @oauth_locale = determine_oauth_effective_locale
  Rails.logger.info "OAuth locale determined: #{@oauth_locale} (sources: params=#{omniauth_locale_from_params}, session=#{omniauth_locale_from_session})"
end

private

def determine_oauth_effective_locale
  # omniauth.params優先、セッションフォールバック、その他の順で決定
  omniauth_locale_from_params || 
  omniauth_locale_from_session || 
  user_preference_locale ||
  browser_locale ||
  I18n.default_locale.to_s
end
```

## テスト戦略

1. **OAuth開始からコールバックまでの完全フロー**
2. **各種ロケール決定シナリオ**
3. **エラー状況での言語表示**
4. **複数ブラウザタブでの動作確認**

## メリット

1. **確実な言語引き継ぎ**: 複数のフォールバック戦略により高い成功率
2. **リファクタリング計画との整合性**: 明示的ロケール必須化と矛盾しない
3. **ユーザー体験の向上**: 認証前後での言語の一貫性
4. **保守性の向上**: 設定変更や新プロバイダー追加時の影響最小化

## 注意点

1. **セッション依存**: セッションストレージの可用性に依存
2. **プライバシー**: 言語設定がセッションに一時保存される
3. **タイムアウト管理**: 古いセッション情報の適切なクリーンアップが必要
4. **マルチプロバイダー対応**: 将来的なGoogle、Twitter等への対応考慮

この戦略により、OAuth認証時の言語引き継ぎを確実に行い、同時にリファクタリング計画との整合性も保つことができます。
