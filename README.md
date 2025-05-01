# Annabelle アナベル

Annabelle is a simple message board developed as part of my personal Ruby on Rails training. Its purpose is to facilitate file and message exchange between PCs and smartphones on a local area network (LAN). It is not intended to be used as a publicly accessible site.

Annabelle は、私個人の Ruby on Rails トレーニングの一環として開発された簡易な掲示板です。PC やスマートフォン間でファイルやメッセージをやり取りすることを目的としており、公開サイトとしての利用は想定していません。

## Features 機能

### Realtime Messaging / リアルタイム・メッセージ

Messages posted or deleted by other users (browser sessions) are instantly reflected on the screen via Action Cable. It can also be used like a chat interface.

他のユーザ（ブラウザセッション）によるメッセージの投稿や削除が、Action Cable を通じて即座に画面に反映されます。チャットのように利用することも可能です。

### File Upload / ファイルアップロード

Multiple files can be selected and uploaded at once. (Currently, uploaded files are stored locally only.)

複数のファイルを同時に選択してアップロードできます。（現時点では、アップロードされたファイルはローカルディスクに保存されます。）

### Layout / 画面レイアウト

The screen layout is optimized to allow quick preview of uploaded media such as images or videos. On PC screens, the right half is dedicated to previews, while on mobile devices, a modal window is used.

アップロードされたメディア（画像や動画）をすばやく確認できるように、画面レイアウトが工夫されています。PC では画面の右半分がプレビュー領域となり、モバイルではモーダルウィンドウが使用されます。

### User Authentication / ユーザ認証

Users can sign in using either their email address or via GitHub OAuth (currently, only GitHub is supported). OAuth is optional; even if a user registers via OAuth, the account will be created using the email address obtained during authentication.

ユーザはメールアドレスまたは GitHub OAuth（現時点では GitHub のみ対応）を利用してサインインできます。OAuth はオプションで、OAuth を使って初回登録した場合でも、認証時に取得されるメールアドレスをもとにユーザが登録されます。

## Requirements 要件

### libvips

This project requires [libvips](https://github.com/libvips/libvips) to be installed on the system for Active Storage.

このプロジェクトでは、Active Storage のために libvips がシステムにインストールされている必要があります。

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

### 1. DB

First, run the database migrations and seed the database:

最初に、`rails db:migrate` と `rails db:seed` を実行してください。

```
$ rails db:migrate
$ rails db:seed
```

This process will create an administrator user in the `users` table. Please change the administrator's password as follows:

この処理で `users` テーブルに管理者ユーザが作成されます。管理者ユーザのパスワードは以下の手順で変更してください。

```
$ rails c
> user = User.admin_user
> user.password = 'foo bar baz'
> user.save!
```

### 2. Environment Variables / 環境変数

Set the necessary environment variables to run the application.

アプリケーションを動作させるために、必要な環境変数を設定してください。

If you are using dotenv, you can rename the sample file `dot.env.skel` to `.env` as a starting point. (Note: this app does not require a `.env` file, but using dotenv is convenient for managing environment variables.)

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
$ rails s
```

Then, access the homepage via your browser.

その後、ブラウザでトップページにアクセスします。

Please note that the production environment is not supported at this time. Run the server in development mode:

なお、本プロジェクトは現時点では本番環境に対応していないため、`RAILS_ENV=development` で実行してください。

During development, it is useful to run the Tailwind CSS watcher concurrently. Alternatively, you can use `bin/dev` to run multiple processes at once. A sample configuration is provided in `Procfile.dev.skel`, which you can customize as needed.

開発中は、Tailwind 用に `bin/rails tailwindcss:watch` を同時に実行すると便利です。また、複数のプロセスを同時に起動するために `bin/dev` も利用可能です。雛形として `Procfile.dev.skel` が用意されているので、必要に応じてカスタマイズしてください。

## License ライセンス

MIT License

MIT ライセンス
