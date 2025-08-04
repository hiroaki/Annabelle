# Development Environment / 開発環境の構築

If you want to develop based on this project, please clone the repository and set up your environment as follows.

このプロジェクトをベースに開発する場合は、リポジトリをクローンし、以下のようにして環境を構築してください。


## 1. Preparing DB / データベースのセットアップ

First, run the database migrations and seed the database:

最初に、データベースをセットアップしてください：

```
$ bin/rails db:prepare
```

This process will create an administrator user in the `users` table. Please change the administrator's password as follows:

この処理で `users` テーブルに管理者ユーザが作成されます。管理者ユーザのパスワードは次の手順で変更してください：

```
$ bin/rails c
> user = User.admin_user
> user.password = 'YOU MUST CHANGE THIS!'
> user.save!
```

Note: Please do not change any values other than the password in the current version.

注意：現時点ではパスワード以外の値は変更しないでください。


## 2. Environment Variables / 環境変数

Set the necessary environment variables to run the application.

アプリケーションを動作させるために、 [/docs/ENVIRONMENT_VARIABLES.md](/docs/ENVIRONMENT_VARIABLES.md) に記載されている環境変数を設定してください。


## 3. Build Tailwind CSS / Tailwind CSS のビルド

This project uses Tailwind for CSS. You need to build the CSS files with the following command:

このプロジェクトの CSS には Tailwind を使用しています。 CSS ファイルのビルドが必要なため、次のコマンドを実行してください：

```
$ bin/rails tailwindcss:build
```

Whenever you make changes to the CSS, you need to rebuild it. Therefore, during development, it is convenient to run `bin/rails tailwindcss:watch` concurrently to automatically build Tailwind CSS. You can also use `bin/dev` to launch multiple processes at once. A sample configuration is provided in `Procfile.dev.skel`, which you can customize as needed.

CSS の変更のたびに、ビルドが必要です。したがって開発中は、 Tailwind CSS の自動ビルドのために `bin/rails tailwindcss:watch` を同時に実行しておくと便利です。また、複数のプロセスを同時に起動するために `bin/dev` も利用可能です。雛形として `Procfile.dev.skel` が用意されているので、必要に応じてカスタマイズしてください。


## 4. Run / 実行

Once everything is configured, start the web server by running.

全ての設定が完了したら、Web サーバを以下のコマンドで起動してください。

```
$ bin/rails s -b 0.0.0.0 -p 3000
```

Then, access the homepage via your browser.

その後、ブラウザでトップページにアクセスします。


# Customization Guide / カスタマイズ・ガイド

If you wish to use this application as a base for your own extensions, please refer to this section as a guide.

このアプリをベースに独自に拡張される場合は、本セクションを参考ガイドとしてご活用ください。

## Project Structure / プロジェクト構成

This project follows the standard Ruby on Rails directory structure and conventions. If you wish to add new features or customize the application, please follow the Rails way for controllers, models, views, and configurations.

本プロジェクトは Ruby on Rails の標準的なディレクトリ構成および慣習に従っています。新しい機能の追加やカスタマイズを行う場合は、コントローラ・モデル・ビュー・設定など、Rails の流儀に従って実装してください。

If any custom features that deviate from the standard are added in the future, they will be documented in this section.

標準から外れる独自の部分が今後追加された場合は、このセクションに追記していく予定です。

## I18n (Locales) / 国際化（ロケール）

This application follows the [internationalization section of the Rails Guides](https://guides.rubyonrails.org/i18n.html) for internationalization setup. For per-request locale setting, URL parameters are used, with locale being mandatory in routing.

[Rails ガイドの国際化のセクション](https://railsguides.jp/i18n.html)に基づき設定しています。リクエストごとのロケールの設定については URL パラメータを採用し、ルーティングでロケールを必須としています。

```
scope ":locale", locale: /en|ja/ do
  ...
```

The default locale is "en".

デフォルトのロケールは "en" です。

Translations are available for both "en" and "ja". When adding new items, please update both translation files.

また訳文については "en" と "ja" が用意されています。項目を追加した際はいずれの訳文についても更新してください。

A rake task has been created to check whether other language translation items are sufficient (or excessive) compared to the default locale.

デフォルトロケールに対して、ほかの言語の訳文の項目が足りているか（または余分があるか）をチェックするツールを rake タスクとして作りましたので、これを用いてチェックすることができます。

```
$ rails -T | grep locale
bin/rails locale:check                       # Check locale file structure consistency
bin/rails locale:diff                        # Show locale structure differences
$ bin/rails locale:check
[SUCCESS] All app-defined locale files have consistent structure
$ bin/rails locale:diff
Base locale (en) has 95 keys (app-defined only)
============================================================

JA locale:
  Total keys: 95
  [Perfect] match with base locale
$
```

All locale-related parts were developed through conversations with GitHub Copilot, with the coding based on LLM model outputs. The models primarily used were "GPT-4.1" and "Claude Sonnet 4 (Preview)".

なおロケールに関する部分は、すべてが GitHub Copilot との会話でのやりとりを経ながら、コーディングについては LLM モデルの出力によるものになってます。モデルは "GPT-4.1" および "Claude Sonnet 4 (Preview)" を主に用いています。

For implementation details around locales, please refer to the documentation in [/docs/LOCALE_SYSTEM_DESCRIPTION.md](/docs/LOCALE_SYSTEM_DESCRIPTION.md).

ロケール周りの実装について、説明文を [/docs/LOCALE_SYSTEM_DESCRIPTION.md](/docs/LOCALE_SYSTEM_DESCRIPTION.md) にまとめていますので、そちらを参照してください。

## Flash Message / フラッシュ・メッセージ

A unique implementation is used for flash messages, which are temporary messages displayed to users, in this application.

一時的に表示されるメッセージであるフラッシュ・メッセージについて、このアプリでは独特の実装をしています。

Normally, flash objects containing messages are expanded within templates and rendered as part of the page. In Annabelle, while the messages are still embedded in the page, the actual rendering (formatting) is handled on the client side (JavaScript).

通常であればメッセージがセットされた flash オブジェクトを、テンプレートの中で展開して、ページの一部として render させるように扱われます。それに対して Annabelle では、ページの一部に埋め込むのは同じではありますが、それをページの一部として描画（整形）するのはクライアント (JavaScript) 側の処理になっています。

This client-side rendering approach solves the following issues:
- Messages in response to error responses from proxies (before the request reaches Rails) can be displayed using the same mechanism.
- Arbitrary messages originating from the client can also be displayed using the same process (and template).

このクライアント・サイドによる描画の仕組みにより、次のことが解決されています：
- （リクエストが Rails に到達する前の） Proxy によるエラー・レスポンスに応じたメッセージを同じ仕組みで表示させる
- クライアント由来の任意のメッセージも同じ処理（同じテンプレート）で表示させる

On the server side, flash messages are set as usual:

サーバーのアクションは通常のとおり、フラッシュ・メッセージをセットします：

```
flash.now.alert = I18n.t("messages.errors.generic", error_message: "Something Wrong!")
```

For processing on the JavaScript side, the following HTML structure is output as a hidden element on the page. The element with the data attribute `data-flash-storage` is referred to here as "flash storage" or simply "storage":

JavaScript での処理のために、ページに隠し要素として次の HTML 構造で書き出すようにします。なお、この data 属性 `data-flash-storage` を持った要素を、ここでは "フラッシュ・ストレージ" または単に "ストレージ" と呼称します：

```
<div data-flash-storage style="display: none;">
  <ul>
    <% flash.each do |type, message| %>
      <li data-type="<%= type %>"><%= message %></li>
    <% end %>
  </ul>
</div>
```

This is a standard structure and is provided as the partial 'shared/flash_storage'. By rendering this partial, the above HTML structure will be output:

これは定型のものなので、パーシャル 'shared/flash_storage' として用意されています。つまりこのようにすれば、上記の HTML 構造が書き出されます：

```
<%= render 'shared/flash_storage' %>
```

Alternatively, with Turbo Stream:

または Turbo Stream であればこのように：

```
render turbo_stream: turbo_stream.update('flash-storage', partial: 'shared/flash_storage')
```

To display messages, place an element with the data attribute `data-flash-message-container` (referred to as the "message container") where you want the messages to appear:

そして、メッセージを表示させたい場所には、 data 属性 `data-flash-message-container` を持った要素（ "メッセージ・コンテナ" と呼称します）を配置します：

```
<div data-flash-message-container></div>
```

When a browser receives a page response containing these elements, events configured in advance by the initialization function `initializeFlashMessageSystem` are triggered. The event handler then reconstructs the HTML for the flash messages inside the message container based on the contents of the storage.

これらが埋め込まれたページのレスポンスをブラウザが受け取ると、あらかじめ初期化関数 `initializeFlashMessageSystem` で設定していた、関連するイベントが発火します。そのイベント・ハンドラーがストレージの内容をもとに、メッセージ・コンテナの中のフラッシュ・メッセージの HTML 部分を再構成するようになっています。

To explicitly display messages from JavaScript, use the storage creation function `appendMessageToStorage` to set a message in the storage, then execute the rendering function `renderFlashMessages`.

また、 JavaScript から明示的に表示する場合は、ストレージ作成関数 `appendMessageToStorage` を用いてストレージにメッセージをセットしてから、描画関数 `renderFlashMessages` を実行します。

```
appendMessageToStorage('Something Wrong!', 'alert');
renderFlashMessages();
```

In summary, this mechanism works as follows:
(1) Set a message in the storage
(2) Call the rendering function
This is a two-step process. Since the rendering function handles the display templates, both server-side and client-side messages are displayed in the message container with the same HTML design.


要するに、この仕組みは：
(1) ストレージにメッセージをセットし
(2) 描画関数を呼び出す
という二段回の処理になっているということです。描画関数が表示のためのテンプレートを扱うので、サーバーサイド由来のメッセージも、クライアント由来のメッセージも、同様の HTML デザインでメッセージ・コンテナに表示することになります。

For more details, please refer to the source code comments, which also include usage instructions.

ソースコードのコメントに使い方の説明がありますので、そちらも参照してください。

## Testing / テスト

RSpec tests are provided. Since Capybara uses cuprite as its javascript_driver, Google Chrome is required in the test environment.

RSpec のテストが用意されています。Capybara の javascript_driver に cuprite を使用しているため、テスト実行環境に Google Chrome ブラウザが必要です。

```
$ bin/rspec
```

Regarding tests for OAuth (GitHub), you cannot simultaneously test both contexts—when the feature is enabled and when it is disabled. This is because the enabled/disabled state is determined and set up during Rails initialization. Therefore, you need to run RSpec tests twice (in two separate processes).

OAuth (GitHub) に関するテストについては、その機能を有効化した場合と、無効化した場合とのコンテキストを、同時にテストすることができません。なぜなら Rails の初期化の段階で有効・無効が確定し、セットアップされるためです。したがって RSpec のテストを、二回に分けて（二つのプロセスで）行う必要があります。

To test with OAuth enabled, simply run RSpec as usual. To test with OAuth disabled, set the environment variable `RSPEC_DISABLE_OAUTH_GITHUB` to `1` and specify the directory `spec/system/oauth_github_disabled/` as the target. You may run all spec files, but currently only the tests placed in `spec/system/oauth_github_disabled/` are for the OAuth-disabled context.

OAuth が有効なコンテキストのテストは上述のように、通常の RSpec として実行してください。そして OAuth が無効なコンテキストのテストは環境変数 `RSPEC_DISABLE_OAUTH_GITHUB` に `1` をセットし、実行対象としてディレクトリ `spec/system/oauth_github_disabled/` を指定して実行します。全ての spec ファイルに対して実行しても構いませんが、現時点では `spec/system/oauth_github_disabled/` に置かれたテストだけが、OAuth が無効なコンテキストのテストになっています。

```
$ RSPEC_DISABLE_OAUTH_GITHUB=1 bin/rspec spec/system/oauth_github_disabled/
```

When writing tests affected by this context, please add the tags `oauth_github_required` and `oauth_github_disabled` to the relevant blocks. Tests with the `oauth_github_required` tag will run only when OAuth is enabled, and those with the `oauth_github_disabled` tag will be skipped. The reverse also applies.

このコンテキストが影響するテストを作成する場合は、そのブロックにタグ `oauth_github_required` と `oauth_github_disabled` を付けてください。前者のタグを付けたブロック内は OAuth が有効化されている条件下でのテストとし、タグ `oauth_github_disabled` がついたテストはスキップされます。逆の場合も同様です。

When you run rspec, a coverage report will be generated by simplecov as `coverage/index.html`. Please check the results there. Also, when you run the test suite twice using `RSPEC_DISABLE_OAUTH_GITHUB`, the coverage results will be automatically merged if you run them consecutively.

rspec を実行すると、simplecov によるカバレッジ・レポートが `coverage/index.html` として出力されるので、結果をご覧ください。なお上述した `RSPEC_DISABLE_OAUTH_GITHUB` による二回に分けたテストスイートのカバレッジは、連続して実行することで自動的にマージされます。

If you want to observe the browser during system spec debugging, you can disable headless mode by setting the `HEADLESS` environment variable to `0` when running rspec. You can also specify a value for the `SLOWMO` environment variable to add a delay (in seconds) between each step. Insert `binding.pry` in your code where you want to pause, and run the following command:

system spec でのデバッグのために、ブラウザでの実行の様子を眺めたい場合があるかもしれません。その場合、rspec の実行時に環境変数 `HEADLESS` に `0` を指定するとヘッドレス・モードを解除しますので、ブラウザを操作している様子を見ることができます。また環境変数 `SLOWMO` に数値を指定すると、操作のステップごとにその秒数のディレイが入ります。コード上で止めたい場所に `binding.pry` などを挟んでおき、次のように実行するとよいでしょう：

```
$ HEADLESS=0 SLOWMO=0.5 bin/rspec ./spec/system/something_spec.rb:123
```

This idea was inspired by [Upgrading from Selenium to Cuprite](https://janko.io/upgrading-from-selenium-to-cuprite/). Thank you.

このアイデアは [Rails: SeleniumをCupriteにアップグレードする（翻訳）](https://techracho.bpsinc.jp/hachi8833/2023_10_16/133982) から頂きました。ありがとうございます。


# Docker Environment / Docker 環境

Docker environment is also available for testing purposes. See [/docker/README.md](/docker/README.md) for details.

テストを実施するための用途限定で、 Docker 環境での構築をサポートしています。 [/docker/README.md](/docker/README.md) を参照してください。
