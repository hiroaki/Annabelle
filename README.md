# Annabelle アナベル

Annabelle is a simple message board developed as part of my personal Ruby on Rails training. It is intended to facilitate file and message exchange between PCs and smartphones on a local area network (LAN). Since it also includes experimental implementations, it is not recommended for use as a publicly accessible site.

Annabelle は、私個人の Ruby on Rails トレーニングの一環として開発された簡易な掲示板です。 LAN 内の PC やスマートフォン間でファイルやメッセージをやり取りすることを目的としており、また実験的な実装も盛り込むため、公開サイトとしての利用は推奨しません。

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

## Requirements 要件

### Image Processing Library / 画像処理ライブラリ

This project uses ImageMagick (via mini_magick gem) for Active Storage image and video processing by default, for better compatibility with older operating systems and environments. If you prefer to use libvips instead, set the environment variable `ANNABELLE_VARIANT_PROCESSOR` to `vips` before starting the application.

このプロジェクトでは、古い OS や環境との互換性向上のため、Active Storage の画像・動画処理にデフォルトで ImageMagick（mini_magick gem 経由）を使用しています。libvips を利用したい場合は、アプリケーション起動前に環境変数 `ANNABELLE_VARIANT_PROCESSOR` を `vips` に設定してください。

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

最初に、`bin/rails db:migrate` と `bin/rails db:seed` を実行してください。

```
$ bin/rails db:migrate
$ bin/rails db:seed
```

This process will create an administrator user in the `users` table. Please change the administrator's password as follows:

この処理で `users` テーブルに管理者ユーザが作成されます。管理者ユーザのパスワードは以下の手順で変更してください。

```
$ bin/rails c
> user = User.admin_user
> user.password = 'foo bar baz'
> user.save!
```

Note: Please do not change any values other than the password in the current version.

注意：現時点ではパスワード以外の値は変更しないでください。

### 2. Environment Variables / 環境変数

Set the necessary environment variables to run the application.

アプリケーションを動作させるために、必要な環境変数を設定してください。

If you are using dotenv, you can rename the sample file `dot.env.skel` to `.env` as a starting point. (Note: while this app does not require a .env file, using dotenv is a convenient way to manage environment variables.)

dotenv を利用する場合は、サンプルファイル `dot.env.skel` を `.env` にリネームして利用してください。（本アプリでは `.env` ファイルは必須ではありませんが、環境変数の管理には dotenv を利用すると便利です。）

Set the following variables for SMTP configuration:

SMTP サーバ設定のため、以下の変数を設定してください。

```
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_DOMAIN=example.com
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
```

These variables are also used to indicate the application's location in outgoing emails:

これらの変数は、送信されるメール本文中にアプリのロケーションを示すためにも利用されます。

```
APP_HTTP_HOST=www.example.com
APP_HTTP_PORT=3000
APP_HTTP_PROTOCOL=https
```

Set the following variables for GitHub authentication:

GitHub 認証のため、以下の変数を設定してください。

```
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
```

### 3. Run / 実行方法

Once everything is configured, start the web server by running:

全ての設定が完了したら、Web サーバを以下のコマンドで起動してください。

```
$ bin/rails s
```

Then, access the homepage via your browser.

その後、ブラウザでトップページにアクセスします。

Please note that the production environment is not supported at this time. Run the server in development mode.

なお、本プロジェクトは現時点では本番環境に対応していないため、`RAILS_ENV=development` で実行してください。

During development, it is useful to run the Tailwind CSS watcher concurrently. Alternatively, you can use `bin/dev` to run multiple processes at once. A sample configuration is provided in `Procfile.dev.skel`, which you can customize as needed.

開発中は、Tailwind 用に `bin/rails tailwindcss:watch` を同時に実行すると便利です。また、複数のプロセスを同時に起動するために `bin/dev` も利用可能です。雛形として `Procfile.dev.skel` が用意されているので、必要に応じてカスタマイズしてください。

If you only want to use this application (not develop it), please run the following command once at the beginning:

（開発するのではなく）単にこのアプリを利用する場合は、最初一回だけ、次のコマンドを実行してください：

```
$ bin/rails assets:precompile
```

### 4. Operation / 運用について

Session information is stored in the database using [activerecord-session_store](https://github.com/rails/activerecord-session_store). Since old session records will remain unless cleaned up, please make sure to delete them periodically. A rake task is provided for this purpose, which deletes sessions older than 30 days by default. To specify a different threshold, set the number of days via the SESSION_DAYS_TRIM_THRESHOLD environment variable before running the task.

セッション情報は [activerecord-session_store](https://github.com/rails/activerecord-session_store) を用いてデータベースに保存しています。古いセッションのレコードが残るため、定期的に削除してください。削除のための rake タスクがあり、実行すると、デフォルトでは 30日を経過したものが削除されます。この日数を指定したい場合は環境変数 `SESSION_DAYS_TRIM_THRESHOLD` に日数を指定して実行してください。

```
$ SESSION_DAYS_TRIM_THRESHOLD=30 bin/rails db:sessions:trim
```

## License ライセンス

MIT License

MIT ライセンス
