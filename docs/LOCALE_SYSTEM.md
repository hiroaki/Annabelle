# Locale System / ロケールシステム (改修前の状態)

⚠️ **重要**: このドキュメントは改修前の現在のシステムを記録したものです。
改修計画については `LOCALE_REFACTORING_MASTER_PLAN.md` を参照してください。

This document explains the locale system architecture and usage rules for developers.

開発者向けのロケールシステムのアーキテクチャと使用ルールを説明します。

## URL-based Locale Configuration / URLベースのロケール設定

The system uses URL-based locale configuration with the following rules:

システムは以下のルールでURLベースのロケール設定を使用します：

### URL Patterns / URLパターン

The system uses **URL path-based locale configuration** as the primary method, with query parameter fallback for temporary switching:

システムは**URLパスベースのロケール設定**を主要な方法として使用し、一時的な切り替えのためのクエリパラメータ代替を提供します：

**Primary URL structure / 基本URL構造:**
- Default locale (English): `/` → `/users`, `/messages` (no prefix needed)
- Non-default locale (Japanese): `/ja/` → `/ja/users`, `/ja/messages` (with prefix)

**Temporary switching / 一時的な切り替え:**
- Query parameter fallback: `/?lang=ja`, `/ja/users?lang=en` (temporary language preview)

### Locale Detection Priority / ロケール判定優先順位

1. **Explicit parameter** / **明示的なパラメータ** (`locale_service.set_locale('ja')`)
2. **URL query parameter** / **URLクエリパラメータ** (`?lang=ja`)
3. **URL path locale** / **URLパスロケール** (`/ja/users`)
4. **User preferences** / **ユーザー設定** (`user.preferred_language`)
5. **Browser Accept-Language** / **ブラウザ言語設定** (`Accept-Language: ja`)
6. **Default locale** / **デフォルトロケール** (`:en`)


## Architecture / アーキテクチャ

The locale system follows a layered architecture with clear separation of responsibilities:

ロケールシステムは責任を明確に分離したレイヤードアーキテクチャに従います：

```
View Layer
    ↓ (Use LocaleHelper only)
LocaleHelper (Pure Utility Functions)
    ↓ (Path manipulation, string processing)
LocaleService (Business Logic)
    ↓ (Locale determination, user preferences)
Controller Layer
```

### LocaleHelper

**Pure utility functions for path and URL manipulation.**

**パスとURL操作のための純粋関数群**

- `current_path_with_locale(request, locale)` - Generate URL with locale parameter
- `remove_locale_prefix(path)` - Remove locale prefix from path
- `add_locale_prefix(path, locale)` - Add locale prefix to path
- `skip_locale_redirect?(path)` - Check if path should skip locale redirect
- `url_indicates_default_locale?(params, path)` - Check if URL indicates default locale

### LocaleService

**Business logic for locale determination and user preferences.**

**ロケール決定とユーザー設定のためのビジネスロジック**

- `extract_from_user(user)` - Extract locale from user preferences
- `extract_from_header(header)` - Extract locale from HTTP Accept-Language header
- `redirect_path_for_user(resource)` - Determine redirect path based on user settings
- `determine_effective_locale(locale = nil)` - Main locale determination logic
- `set_locale(locale = nil)` - Set I18n.locale
- `determine_post_login_redirect_path(resource)` - Determine post-login redirect
- `current_path_with_locale(locale)` - Delegate to LocaleHelper


## Usage Rules / 使用ルール

⚠️ Important: Follow the layer boundaries

⚠️ 重要：レイヤー境界を守ること

### From Views / ビューから

```erb
<!-- ✅ GOOD: Use LocaleHelper directly -->
<%= link_to "日本語", LocaleHelper.current_path_with_locale(request, :ja) %>
<%= link_to "English", LocaleHelper.current_path_with_locale(request, :en) %>

<!-- ❌ BAD: Don't use LocaleService from views -->
<%= link_to "日本語", locale_service.current_path_with_locale(:ja) %>
```

### From Controllers / コントローラーから

```ruby
# ✅ GOOD: Use LocaleService for business logic
def update
  header_locale = locale_service.extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
  effective_locale = locale_service.determine_effective_locale(params[:preferred_language])
  # ...
end

# ❌ BAD: Don't use LocaleHelper for business logic from controllers
def update
  header_locale = LocaleHelper.extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE']) # This method doesn't exist anymore
  # ...
end

# ⚠️ AVOID: Direct LocaleHelper usage from controllers
# While technically possible for pure utility functions, prefer consistency
def some_method
  clean_path = LocaleHelper.remove_locale_prefix(request.path) # Avoid this
  # ...
end

# ✅ BETTER: Use LocaleService consistently, even for utilities
def some_method
  # If you need utility functions, consider adding them to LocaleService
  # or create a dedicated method that delegates to LocaleHelper
  clean_path = locale_service.remove_locale_prefix(request.path) # Would need to add this method
  # ...
end
```

### From Services / サービスから

```ruby
# ✅ GOOD: Services can use LocaleHelper utilities
class SomeService
  def process_path(path, locale)
    clean_path = LocaleHelper.remove_locale_prefix(path)
    localized_path = LocaleHelper.add_locale_prefix(clean_path, locale)
    # ...
  end
end
```

## Key Points / 重要なポイント

1. **LocaleHelper = Stateless utilities** / **LocaleHelper = ステートレスなユーティリティ**
   - Pure functions only
   - No business logic
   - Safe to call from anywhere

2. **LocaleService = Stateful business logic** / **LocaleService = ステートフルなビジネスロジック**
   - Requires controller context
   - Handles user preferences
   - Use from controllers only

3. **Consistency** / **一貫性**
   - **Controllers should always use LocaleService** for locale-related operations
   - **Views should use LocaleHelper** for URL generation and pure utilities
   - **Avoid mixing patterns** - maintain clear boundaries

## Example Implementation / 実装例

### Language Switcher in View / ビューでの言語切り替え

```erb
<!-- app/views/shared/_language_switcher.html.erb -->
<div class="language-switcher">
  <%= link_to_unless_current "日本語", 
      LocaleHelper.current_path_with_locale(request, :ja),
      class: "hover:text-slate-600 #{I18n.locale == :ja ? 'font-bold' : ''}" %>
  <span>|</span>
  <%= link_to_unless_current "English", 
      LocaleHelper.current_path_with_locale(request, :en),
      class: "hover:text-slate-600 #{I18n.locale == :en ? 'font-bold' : ''}" %>
</div>
```

**How it works / 動作原理:**

The system primarily uses URL path-based locale configuration (e.g., `/ja/users`), but allows temporary language switching via query parameters (`?lang=ja`). The language switcher uses query parameters to provide immediate feedback without changing the current URL structure.

システムは主にURLパスベースのロケール設定（例：`/ja/users`）を使用しますが、クエリパラメータ（`?lang=ja`）による一時的な言語切り替えも可能です。言語切り替えリンクは、現在のURL構造を変更せずに即座にフィードバックを提供するためクエリパラメータを使用します。

**Generated URLs examples:**
- From `/users` (English page) → Japanese link: `/users?lang=ja` (temporary switch)
- From `/ja/users` (Japanese page) → English link: `/ja/users?lang=en` (temporary switch)
- From `/` (English home) → Japanese link: `/?lang=ja` (temporary switch)

**生成されるURL例:**
- `/users`（英語ページ）から → 日本語リンク: `/users?lang=ja`（一時切り替え）
- `/ja/users`（日本語ページ）から → 英語リンク: `/ja/users?lang=en`（一時切り替え）  
- `/`（英語ホーム）から → 日本語リンク: `/?lang=ja`（一時切り替え）

**Query parameter behavior / クエリパラメータの動作:**
- Query parameters (`?lang=ja`) provide **temporary** language switching
- After navigation, the system returns to the URL-based locale structure
- This allows users to preview content in different languages without permanent URL changes

**クエリパラメータの動作:**
- クエリパラメータ（`?lang=ja`）は**一時的な**言語切り替えを提供
- ナビゲーション後は、URLベースのロケール構造に戻る
- ユーザーは恒久的なURL変更なしに、異なる言語でコンテンツをプレビューできる

This architecture ensures maintainable and consistent locale handling across the application.

このアーキテクチャにより、アプリケーション全体で保守しやすく一貫したロケール処理が保証されます。

## Best Practices / ベストプラクティス

### URL Design / URL設計

1. **Keep default locale clean** / **デフォルトロケールはクリーンに**
   - ✅ Good: `/`, `/users`, `/messages` (English)
   - ❌ Avoid: `/en/`, `/en/users` (redundant for default)

2. **Consistent non-default locale paths** / **非デフォルトロケールパスの一貫性**
   - ✅ Good: `/ja/`, `/ja/users`, `/ja/messages`
   - ❌ Avoid: mixing `/ja/users` and `/users?lang=ja` patterns

3. **Query parameters for temporary switching / 一時切り替えのためのクエリパラメータ**
   - Use `?lang=ja` for language switcher links (immediate preview)
   - Use `?lang=en` for temporary language switching without changing URL structure  
   - Perfect for testing content in different languages
   - Users can bookmark the clean URL structure (`/ja/users`) for permanent preference

4. **When to use each approach / 各アプローチの使い分け**
   - **URL path** (`/ja/users`): Permanent locale, SEO-friendly, bookmarkable
   - **Query parameter** (`/users?lang=ja`): Temporary preview, language switcher, testing

### Locale Configuration / ロケール設定

```ruby
# config/application.rb
config.i18n.default_locale = :en
config.i18n.available_locales = [:en, :ja]
```

⚠️ **Configuration Note**: **Avoid changing the default locale after initial deployment**
- Changing default locale affects existing URLs and user bookmarks
- Search engines may be confused by URL structure changes
- External links from other sites may point to unexpected language content
- Users' saved links may display different language than expected

⚠️ **設定に関する注意**: **一度設定したデフォルトロケールの変更を避けてください**
- デフォルトロケールの変更は既存URLとユーザーブックマークに影響
- 検索エンジンがURL構造変更により混乱する可能性
- 他サイトからの外部リンクが予期しない言語コンテンツを指す可能性
- ユーザーの保存済みリンクが期待と異なる言語で表示される可能性

**Safe changes you can make:**
- ✅ Add new locales to `available_locales` (e.g., add `:fr`, `:de`)
- ✅ Remove unused locales (with proper planning)
- ❌ Change `default_locale` from `:en` to another value

**安全に変更できる内容:**
- ✅ `available_locales`への新しいロケール追加（例：`:fr`、`:de`の追加）
- ✅ 未使用ロケールの削除（適切な計画とともに）
- ❌ `default_locale`を`:en`から他の値に変更

### Route Configuration / ルート設定

Ensure your routes support locale prefixes:

ルートがロケールプレフィックスをサポートするよう設定してください：

```ruby
# config/routes.rb
scope "(:locale)", locale: /en|ja/ do
  # Your routes here
end
```
