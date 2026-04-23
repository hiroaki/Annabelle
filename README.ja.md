![Coveralls](https://img.shields.io/coverallsCoverage/github/hiroaki/Annabelle?branch=develop)

[English version is here](README.md)

# アナベル

Annabelle は、私個人の Ruby on Rails トレーニングの一環として開発された簡易な掲示板です。 LAN 内の PC やスマートフォン間でファイルやメッセージをやり取りすることを目的としています。実験的な実装も盛り込むため、不特定多数に公開するサイトとしての利用は推奨しません。

## 機能

### リアルタイム・メッセージ

他のユーザによるメッセージの投稿や削除が、Action Cable を通じて即座に画面に反映されます。チャットのように利用することも可能です。

### ファイルアップロード

メッセージに添付する形で、複数のファイルを同時に選択してアップロードできます。（注：現時点では、アップロードされたファイルは暗号化されずにローカルディスクに保存されます。）

### 画面レイアウト

アップロードされたメディア（画像や動画）をすばやく確認できるように、画面レイアウトが工夫されています。プレビュー領域は、デスクトップ向けには画面の右半分が、モバイルではモーダルウィンドウが使用されます。

### プレビュー機能

プレビュー可能なメディアは次のとおりです。これら以外のメディア対応についても今後追加していく予定です：
- テキスト
- 画像（画像と、位置情報が含まれていれば OpenStreetMap の地図で位置を表示します）
- 動画
- GPX（位置情報を OpenStreetMap の地図でウェイポイントやトラックを表示します）

### ユーザ認証

ユーザはメールアドレスまたは OAuth を利用してサインインできます（現時点では GitHub のみ対応）。 OAuth はオプションで、 OAuth を使って初回登録した場合でも、認証時に取得されるメールアドレスをもとにユーザが登録されます。

### 二要素認証

ユーザ認証に追加のオプションで、タイムベースのワンタイムパスワード (TOTP) による二要素認証 (2FA) が利用できます。

なおこの実装にあたっては James Ridgway 氏による記事が大変参考になりました。ありがとうございます。

[Implementing OTP two-factor authentication as a second login step with Rails and Devise](https://www.jamesridgway.co.uk/implementing-a-two-step-otp-u2f-login-workflow-with-rails-and-devise/)

### Basic 認証

ユーザ認証とは別に、 Basic 認証をかけることができます。ユーザ認証はユーザを登録することでサイトを利用できますが、 Basic 認証を構えることでサイトそのものの利用を制限できます。

## 要件

### 画像処理ライブラリ

このプロジェクトでは、Active Storage の画像・動画処理に image_processing (gem) を使用しています。

そのバックエンドには古い OS や環境との互換性向上のため、デフォルトで ImageMagick を選択していますので、 ImageMagick がインストールされている必要があります。ただし、 libvips を利用できる場合は ImageMagick の代わりにそれをインストールし、利用することができます。

### 動画処理

Active Storage でアップロードされた動画ファイルのプレビュー（サムネイル生成）や変換処理には、システムに `ffmpeg` がインストールされている必要があります。

### SMTP サーバ

利用者はサインアップに有効なメールアドレスが求められ、またメールアドレスがアカウントの識別子になります。そのためメールを配送する SMTP サーバの設定が必要です。

### Google Chrome ブラウザ

テストには Capybara のドライバとして cuprite (gem) を利用しているため、テスト実行環境に Google Chrome ブラウザが必要です。

### データベース

本プロジェクトは、データベースとして SQLite3 を使用します。データベース専用のプロセスは不要です。

### GitHub アカウント

GitHub OAuth 認証を利用する場合は、プロジェクト用の GitHub OAuth App を作成する必要があります。

## 環境構築

### 開発環境の構築

[/docs/DEVELOPMENT.ja.md](/docs/DEVELOPMENT.ja.md) を参照してください。 Docker Compose が利用できるのであれば、ビルドするだけです：

```
$ docker compose up --build
```

### ステージング環境の構築

[/docs/DEPLOY.ja.md](/docs/DEPLOY.ja.md) を参照してください。

## 運用について

### セッション情報のクリーンアップ

セッション情報は [activerecord-session_store](https://github.com/rails/activerecord-session_store) を用いてデータベースに保存しています。古いセッションのレコードが残るため、定期的に削除してください。削除のための rake タスクがあり、実行すると、デフォルトでは 30日を経過したものが削除されます。この日数を指定したい場合は環境変数 `SESSION_DAYS_TRIM_THRESHOLD` に日数を指定して実行してください。

```
$ SESSION_DAYS_TRIM_THRESHOLD=30 bin/rails db:sessions:trim
```

### Active Storage のクリーンアップ

Active Storage の孤立ファイル（例：メッセージを削除しても添付が物理削除されない場合）を安全にクリーンアップするための rake タスクを用意しています。

```bash
# 確認のみ（削除はしません）
$ bin/rake active_storage:cleanup

# 削除を実行（purge_later をエンキュー）
$ bin/rake active_storage:cleanup FORCE=true

# 7日より古い孤立ファイルを削除対象（デフォルト2日）
$ bin/rake active_storage:cleanup FORCE=true DAYS_OLD=7
```

## ライセンス

このプロジェクトは Zero-Clause BSD ライセンス（0BSD）の下で提供されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。
