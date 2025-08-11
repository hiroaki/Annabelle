[![Coverage Status](https://coveralls.io/repos/github/hiroaki/Annabelle/badge.svg?branch=develop)](https://coveralls.io/github/hiroaki/Annabelle?branch=develop)

# Annabelle / アナベル

Annabelle is a lightweight message board developed as part of my personal Ruby on Rails training. It is intended for exchanging files and messages between PCs and smartphones on a local area network (LAN). As it includes experimental features, it is not recommended for public use or access by the general public.

Annabelle は、私個人の Ruby on Rails トレーニングの一環として開発された簡易な掲示板です。 LAN 内の PC やスマートフォン間でファイルやメッセージをやり取りすることを目的としています。実験的な実装も盛り込むため、不特定多数に公開するサイトとしての利用は推奨しません。

## Features / 機能

### Realtime Messaging / リアルタイム・メッセージ

Messages posted or deleted by other users are instantly reflected on the screen via Action Cable. It can also be used like a chat interface.

他のユーザによるメッセージの投稿や削除が、Action Cable を通じて即座に画面に反映されます。チャットのように利用することも可能です。

### Layout / 画面レイアウト

The screen layout is optimized for quick preview of uploaded media such as images or videos. On PC screens, the right half is dedicated to previews, while on mobile devices, a modal window is used.

アップロードされたメディア（画像や動画）をすばやく確認できるように、画面レイアウトが工夫されています。PC では画面の右半分がプレビュー領域となり、モバイルではモーダルウィンドウが使用されます。

### File Upload / ファイルアップロード

Multiple files can be selected and uploaded at once. Currently, uploaded files are saved unencrypted on the local disk.

複数のファイルを同時に選択してアップロードできます。現時点では、アップロードされたファイルは暗号化されずにローカルディスクに保存されます。

### User Authentication / ユーザ認証

Users can sign in using either their email address or via OAuth (currently, only GitHub is supported). OAuth is optional. Even when registering via OAuth, the user account will be created based on the email address retrieved during authentication.

ユーザはメールアドレスまたは OAuth を利用してサインインできます（現時点では GitHub のみ対応）。 OAuth はオプションで、 OAuth を使って初回登録した場合でも、認証時に取得されるメールアドレスをもとにユーザが登録されます。

### Two Factor Authentication / 二要素認証

An additional option for user authentication is available: two-factor authentication (2FA) using time-based one-time passwords (TOTP).

ユーザ認証に追加のオプションで、タイムベースのワンタイムパスワード (TOTP) による二要素認証 (2FA) が利用できます。

This implementation was based on an article by James Ridgway, which was extremely helpful. Thank you.

なおこの実装にあたっては James Ridgway 氏による記事が大変参考になりました。ありがとうございます。

[Implementing OTP two-factor authentication as a second login step with Rails and Devise](https://www.jamesridgway.co.uk/implementing-a-two-step-otp-u2f-login-workflow-with-rails-and-devise/)

### Bacic Authentication / Basic 認証

In addition to user authentication, Basic Authentication can also be enabled. While user authentication allows registered users to access the site, enabling Basic Authentication provides an extra layer of access control for the entire site.

ユーザ認証とは別に、 Basic 認証をかけることができます。ユーザ認証はユーザを登録することでサイトを利用できますが、 Basic 認証を構えることでサイトそのものの利用を制限できます。

## Requirements / 要件

### Image Processing Library / 画像処理ライブラリ

This project uses the image_processing gem for Active Storage image and video processing.

このプロジェクトでは、Active Storage の画像・動画処理に image_processing (gem) を使用しています。

For better compatibility with older operating systems and environments, ImageMagick is selected as the default backend. Therefore, you need to have ImageMagick installed. However, if you can use libvips, you may install and use it instead of ImageMagick.

そのバックエンドには古い OS や環境との互換性向上のため、デフォルトで ImageMagick を選択していますので、 ImageMagick がインストールされている必要があります。ただし、 libvips を利用できる場合は ImageMagick の代わりにそれをインストールし、利用することができます。

#### Video Processing / 動画処理

To generate previews (thumbnails) or perform transcoding for video files uploaded via Active Storage, you must have `ffmpeg` installed on your system.

Active Storage でアップロードされた動画ファイルのプレビュー（サムネイル生成）や変換処理には、システムに `ffmpeg` がインストールされている必要があります。

### SMTP Server / SMTP サーバ

A valid email address is required for sign-up, and the email address serves as the account identifier. Therefore, SMTP server configuration is required.

利用者はサインアップに有効なメールアドレスが求められ、またメールアドレスがアカウントの識別子になります。そのためメールを配送する SMTP サーバの設定が必要です。

### Google Chrome Browser / Google Chrome ブラウザ

For testing, this project uses the cuprite (gem) as the driver for Capybara. Therefore, the test environment requires the Google Chrome browser.

テストには Capybara のドライバとして cuprite (gem) を利用しているため、テスト実行環境に Google Chrome ブラウザが必要です。

### Database / データベース

This project uses SQLite3 as its database.

本プロジェクトは、データベースとして SQLite3 を使用します。

### GitHub Account / GitHub アカウント

To enable GitHub OAuth authentication, a GitHub OAuth App must be created for the project.

GitHub OAuth 認証を利用する場合は、プロジェクト用の GitHub OAuth App を作成する必要があります。

## Environment Setup / 環境構築

### Development Environment / 開発環境の構築

See [/docs/DEVELOPMENT.md](/docs/DEVELOPMENT.md)

[/docs/DEVELOPMENT.md](/docs/DEVELOPMENT.md) を参照してください。

### Staging Environment / ステージング環境の構築

See [/docs/DEPLOY.md](/docs/DEPLOY.md)

[/docs/DEPLOY.md](/docs/DEPLOY.md) を参照してください。

## Operation / 運用について

Session information is stored in the database using [activerecord-session_store](https://github.com/rails/activerecord-session_store). Since old session records will remain unless cleaned up, please make sure to delete them periodically. A rake task is provided for this purpose, which deletes sessions older than 30 days by default. To specify a different threshold, set the number of days via the SESSION_DAYS_TRIM_THRESHOLD environment variable before running the task.

セッション情報は [activerecord-session_store](https://github.com/rails/activerecord-session_store) を用いてデータベースに保存しています。古いセッションのレコードが残るため、定期的に削除してください。削除のための rake タスクがあり、実行すると、デフォルトでは 30日を経過したものが削除されます。この日数を指定したい場合は環境変数 `SESSION_DAYS_TRIM_THRESHOLD` に日数を指定して実行してください。

```
$ SESSION_DAYS_TRIM_THRESHOLD=30 bin/rails db:sessions:trim
```

## License / ライセンス

This project is licensed under the Zero-Clause BSD License (0BSD). See the [LICENSE](LICENSE) file for details.

このプロジェクトは Zero-Clause BSD ライセンス（0BSD）の下で提供されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。
