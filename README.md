[![Coverage Status](https://coveralls.io/repos/github/hiroaki/Annabelle/badge.svg?branch=develop)](https://coveralls.io/github/hiroaki/Annabelle?branch=develop)

# Annabelle アナベル

Annabelle is a simple message board developed as part of my personal Ruby on Rails training. Its purpose is to enable file and message exchange between PCs and smartphones on a local area network (LAN). As it is still under development and includes experimental implementations, it is not recommended for use as a public site at this time. (The goal is to eventually make it suitable for public deployment.)

Annabelle は、私個人の Ruby on Rails トレーニングの一環として開発された簡易な掲示板です。 LAN 内の PC やスマートフォン間でファイルやメッセージをやり取りすることを目的としています。現在は開発途上にあり、また実験的な実装も盛り込むため、現時点では一般に公開するサイトとしての利用は推奨しません。（目標としては公開サイトにする予定です）

## Known Limitations 既知の制限事項

- At present, this application is intended for use on a local area network (LAN). It has not yet been fully designed or tested for public internet exposure.
- Security features are minimal and not sufficient for production use. The application does not support production environments (`RAILS_ENV=production` is not supported).
- Uploaded files are stored on the local disk and are not encrypted.
- Experimental features are included and may change or be removed without notice.

- 現時点では、本アプリはローカルネットワーク（LAN）内での利用を想定しています。インターネット上での公開利用はまだ十分には設計・検証されていません。
- セキュリティ機能は最小限であり、本番運用には十分ではありません。本番環境（`RAILS_ENV=production`）には対応していません。
- アップロードされたファイルはローカルディスクに保存され、暗号化されません。
- 実験的な機能が含まれており、予告なく変更・削除される場合があります。

## Features 機能

### Realtime Messaging / リアルタイム・メッセージ

Messages posted or deleted by other users (browser sessions) are instantly reflected on the screen via Action Cable. It can also be used like a chat interface.

他のユーザ（ブラウザセッション）によるメッセージの投稿や削除が、Action Cable を通じて即座に画面に反映されます。チャットのように利用することも可能です。

### Layout / 画面レイアウト

The screen layout is optimized to allow quick preview of uploaded media such as images or videos. On PC screens, the right half is dedicated to previews, while on mobile devices, a modal window is used.

アップロードされたメディア（画像や動画）をすばやく確認できるように、画面レイアウトが工夫されています。PC では画面の右半分がプレビュー領域となり、モバイルではモーダルウィンドウが使用されます。

### File Upload / ファイルアップロード

Multiple files can be selected and uploaded at once. (Currently, uploaded files are stored locally only.)

複数のファイルを同時に選択してアップロードできます。（現時点では、アップロードされたファイルはローカルディスクに保存されます。）

### User Authentication / ユーザ認証

Users can sign in using either their email address or via OAuth (currently, only GitHub is supported). OAuth is optional. Even when registering via OAuth, the user account will be created based on the email address retrieved during authentication.

ユーザはメールアドレスまたは OAuth（現時点では GitHub のみ対応）を利用してサインインできます。OAuth はオプションで、OAuth を使って初回登録した場合でも、認証時に取得されるメールアドレスをもとにユーザが登録されます。

### Two Factor Authentication / 二要素認証

An additional option for user authentication is available: two-factor authentication (2FA) using time-based one-time passwords (TOTP).

ユーザ認証に追加のオプションで、タイムベースのワンタイムパスワード (TOTP) による二要素認証 (2FA) が利用できます。

This implementation was based on an article by James Ridgway, which was extremely helpful. Thank you.

なおこの実装にあたっては James Ridgway 氏による記事が大変参考になりました。ありがとうございます。

[Implementing OTP two-factor authentication as a second login step with Rails and Devise](https://www.jamesridgway.co.uk/implementing-a-two-step-otp-u2f-login-workflow-with-rails-and-devise/)

## Requirements 要件

### Image Processing Library / 画像処理ライブラリ

This project uses the image_processing gem for Active Storage image and video processing, which uses ImageMagick by default for better compatibility with older operating systems and environments. You must have ImageMagick installed on your system. If you prefer to use libvips instead, install libvips and set the environment variable `ANNABELLE_VARIANT_PROCESSOR` to `vips` before starting the application.

このプロジェクトでは、Active Storage の画像・動画処理に image_processing gem を使用しており、古い OS や環境との互換性向上のため、デフォルトで ImageMagick を使用しています。システムに ImageMagick がインストールされている必要があります。libvips を利用したい場合は、libvips をインストールして、アプリケーション起動前に環境変数 `ANNABELLE_VARIANT_PROCESSOR` を `vips` に設定してください。

### SMTP Server / SMTP サーバ

For user sign-up and sign-in, this project uses the devise gem to implement both password authentication and GitHub OAuth authentication. As email notifications may be sent, an SMTP server must be configured.

利用者のサインアップおよびサインインには、devise (gem) を用いてパスワード認証および GitHub OAuth 認証を実装しています。メールが送信される可能性があるため、SMTP サーバの設定が必要です。

### Google Chrome Browser / Google Chrome ブラウザ

For testing, this project uses the cuprite gem as the driver for Capybara. Therefore, the test environment requires the Google Chrome browser.

テストには Capybara のドライバとして cuprite (gem) を利用しているため、テスト実行環境に Google Chrome ブラウザが必要です。

### Database / データベース

This project uses SQLite3 as its database.

本プロジェクトは、データベースとして SQLite3 を使用します。

### GitHub Account / GitHub アカウント

To enable GitHub OAuth authentication, you must create a GitHub OAuth App for your project.

GitHub OAuth 認証を利用する場合は、プロジェクト用の GitHub OAuth App を作成する必要があります。

## Usage 使い方

### 1. Preparing DB / データベースのセットアップ

First, run the database migrations and seed the database:

最初に、データベースをセットアップしてください：

```
$ bin/rails db:create
$ bin/rails db:migrate
$ bin/rails db:seed
```

This process will create an administrator user in the `users` table. Please change the administrator's password as follows:

この処理で `users` テーブルに管理者ユーザが作成されます。管理者ユーザのパスワードは次の手順で変更してください：

```
$ bin/rails c
> user = User.admin_user
> user.password = 'xZgnjs_955nyUX1ijzQo'
> user.save!
```

Note: Please do not change any values other than the password in the current version.

注意：現時点ではパスワード以外の値は変更しないでください。

### 2. Environment Variables / 環境変数

Set the necessary environment variables to run the application.

アプリケーションを動作させるために、必要な環境変数を設定してください。

If you are using dotenv, you can rename the sample file `dot.env.skel` to `.env` as a starting point. (Note: while this app does not require a .env file, using dotenv is a convenient way to manage environment variables.)

dotenv を利用する場合は、サンプルファイル `dot.env.skel` を `.env` にリネームして利用してください。（本アプリでは `.env` ファイルは必須ではありませんが、環境変数の管理には dotenv を利用すると便利です。）

**Important:**
Many of the environment variables described below contain sensitive information (such as passwords, encryption keys, and API secrets). Never commit them to your repository or share them publicly.

**重要:**
以下で設定する多くの環境変数はパスワードや暗号化キー、APIシークレットなどの機密情報を含みます。絶対にリポジトリにコミットしたり、外部に漏らさないよう注意してください。

#### SMTP settings / SMTP 設定

Set the following variables for SMTP configuration:

SMTP サーバ設定のため、以下の変数を設定してください：

```
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_DOMAIN=example.com
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
```

#### App Host / アプリケーション・ホスト

These variables are also used to indicate the application's location in outgoing emails:

これらの変数は、送信されるメール本文中にアプリケーションのロケーションを示すために利用されます：

```
APP_HTTP_HOST=www.example.com
APP_HTTP_PORT=3000
APP_HTTP_PROTOCOL=https
```

#### Active Record Encryption / Active Record 暗号化

Active Record encryption configuration is required for the two-factor authentication implementation. These values can be generated using `bin/rails db:encryption:init`, and you should copy the strings output to the screen and set them to these environment variables:

Active Record 暗号化の設定で、二要素認証の実装のために必要です。これらの値は `bin/rails db:encryption:init` で生成することができ、画面に出力された文字列をコピーして、これらの環境変数に設定してください：

```
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...
```

#### OAuth (GitHub authentication) / OAuth (GitHub 認証)

To use GitHub OAuth authentication, you first need to create an OAuth App for your project on GitHub. You will be asked to enter a callback URL path; for development environments, use the following path (replace the hostname and port as appropriate for your environment):

GitHub OAuth 認証を利用するには、まず GitHub 上でこのプロジェクト用の OAuth アプリを作成してください。その際にコールバック URL のパスを入力する必要がありますが、開発環境に於いては次のパスになります（ホスト名やポート番号は環境に応じて置き換えてください）：

```
http://127.0.0.1:3000/users/auth/github/callback
```

After creating the app, set the following variables using the Client ID and Client Secret provided by GitHub. These credentials allow your application to authenticate users via GitHub:

アプリ作成後、 GitHub から発行される Client ID と Client Secret をこれらの変数に設定してください：

```
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
```

### 3. Build Tailwind CSS / Tailwind CSS のビルド

This project uses Tailwind for CSS. You need to build the CSS files with the following command:

このプロジェクトの CSS には Tailwind を使用しています。 CSS ファイルのビルドが必要なため、次のコマンドを実行してください：

```
$ bin/rails tailwindcss:build
```

### 4. Run / 実行

Once everything is configured, start the web server by running. Please note that the production environment is not supported at this time. Run the server in development mode.

全ての設定が完了したら、Web サーバを以下のコマンドで起動してください。なお、本プロジェクトは現時点では本番環境に対応していないため、`RAILS_ENV=development` で実行してください：

```
$ bin/rails s -b 0.0.0.0 -p 3000
```

Then, access the homepage via your browser.

その後、ブラウザでトップページにアクセスします。

During development, it is convenient to run `bin/rails tailwindcss:watch` concurrently to build Tailwind CSS. You can also use `bin/dev` to launch multiple processes at once. A sample configuration is provided in `Procfile.dev.skel`, which you can customize as needed.

開発中は、 Tailwind CSS のビルド用に `bin/rails tailwindcss:watch` を同時に実行しておくと便利です。また、複数のプロセスを同時に起動するために `bin/dev` も利用可能です。雛形として `Procfile.dev.skel` が用意されているので、必要に応じてカスタマイズしてください。

### 5. Operation / 運用について

Session information is stored in the database using [activerecord-session_store](https://github.com/rails/activerecord-session_store). Since old session records will remain unless cleaned up, please make sure to delete them periodically. A rake task is provided for this purpose, which deletes sessions older than 30 days by default. To specify a different threshold, set the number of days via the SESSION_DAYS_TRIM_THRESHOLD environment variable before running the task.

セッション情報は [activerecord-session_store](https://github.com/rails/activerecord-session_store) を用いてデータベースに保存しています。古いセッションのレコードが残るため、定期的に削除してください。削除のための rake タスクがあり、実行すると、デフォルトでは 30日を経過したものが削除されます。この日数を指定したい場合は環境変数 `SESSION_DAYS_TRIM_THRESHOLD` に日数を指定して実行してください。

```
$ SESSION_DAYS_TRIM_THRESHOLD=30 bin/rails db:sessions:trim
```

## Customization Guide カスタマイズガイド

If you wish to use this application as a base for your own extensions, please refer to this section as a guide.

このアプリをベースに独自に拡張される場合は、本セクションを参考ガイドとしてご活用ください。

### Project Structure / プロジェクト構成

This project follows the standard Ruby on Rails directory structure and conventions. If you wish to add new features or customize the application, please follow the Rails way for controllers, models, views, and configurations.

本プロジェクトは Ruby on Rails の標準的なディレクトリ構成および慣習に従っています。新しい機能の追加やカスタマイズを行う場合は、コントローラ・モデル・ビュー・設定など、Rails の流儀に従って実装してください。

If any custom features that deviate from the standard are added in the future, they will be documented in this section.

標準から外れる独自の部分が今後追加された場合は、このセクションに追記していく予定です。

### I18n (Locales) / 国際化（ロケール）

This application follows the [internationalization section of the Rails Guides](https://guides.rubyonrails.org/i18n.html) for internationalization setup. For per-request locale setting, URL parameters are used, with locale being mandatory in routing.

[Rails ガイドの国際化のセクション](https://railsguides.jp/i18n.html)に基づき設定しています。リクエストごとのロケールの設定については URL パラメータを採用し、ルーティングでロケールを必須としています。

```
scope ":locale", locale: /en|ja/ do
  ...
```

The default locale is "en".

なお、デフォルトのロケールは "en" です。

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

なおロケールに関する部分は、すべてが GitHub Copilot との会話でのやりとりを経ながら、コーディングについては LLM モデルの出力によるものになっています。モデルは "GPT-4.1" および "Claude Sonnet 4 (Preview)" を主に用いています。

For implementation details around locales, please refer to the documentation in [docs/LOCALE_SYSTEM_DESCRIPTION.md](docs/LOCALE_SYSTEM_DESCRIPTION.md).

ロケール周りの実装について、説明文を [docs/LOCALE_SYSTEM_DESCRIPTION.md](docs/LOCALE_SYSTEM_DESCRIPTION.md) にまとめていますので、そちらを参照してください。

### Testing / テスト

RSpec tests are provided. Since Capybara uses cuprite as its javascript_driver, Google Chrome is required in the test environment.

RSpec のテストが用意されています。Capybara の javascript_driver に cuprite を使用しているため、テスト実行環境に Google Chrome ブラウザが必要です。

```
$ bin/rspec
```

When you run rspec, a coverage report will be generated by simplecov as `coverage/index.html`. Please check the results there.

rspec を実行すると、simplecov によるカバレッジ・レポートが `coverage/index.html` として出力されるので、結果をご覧ください。

If you want to observe the browser during system spec debugging, you can disable headless mode by setting the `HEADLESS` environment variable to `0` when running rspec. You can also specify a value for the `SLOWMO` environment variable to add a delay (in seconds) between each step. Insert `binding.pry` in your code where you want to pause, and run the following command:

system spec でのデバッグのために、ブラウザでの実行の様子を眺めたい場合があるかもしれません。その場合、rspec の実行時に環境変数 `HEADLESS` に `0` を指定するとヘッドレス・モードを解除しますので、ブラウザを操作している様子を見ることができます。また環境変数 `SLOWMO` に数値を指定すると、操作のステップごとにその秒数のディレイが入ります。コード上で止めたい場所に `binding.pry` などを挟んでおき、次のように実行するとよいでしょう：

```
$ HEADLESS=0 SLOWMO=0.5 bin/rspec ./spec/system/something_spec.rb:123
```

This idea was inspired by [Upgrading from Selenium to Cuprite](https://janko.io/upgrading-from-selenium-to-cuprite/). Thank you.

このアイデアは [Rails: SeleniumをCupriteにアップグレードする（翻訳）](https://techracho.bpsinc.jp/hachi8833/2023_10_16/133982) から頂きました。ありがとうございます。

### Docker Environment / Docker 環境

Docker environment is also available for testing purposes. See [docker/README.md](docker/README.md) for details.

テストを実施するための用途限定で、 Docker 環境での構築をサポートしています。 [docker/README.md](docker/README.md) を参照してください。

## License ライセンス

This project is licensed under the Zero-Clause BSD License (0BSD) – see the [LICENSE](LICENSE) file for details.

このプロジェクトは Zero-Clause BSD ライセンス（0BSD）の下で提供されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。
