[English version is here](DEVELOPMENT.md)

# 開発環境の構築

このプロジェクトをベースに開発する場合は、リポジトリをクローンした後、次のいずれかの方法で環境を構築してください。

- (A) Docker Compose で構築する
- (B) Docker を使わずに構築する

## (A) Docker Compose で構築する

Compose の設定によって、カレント・ディレクトリがコンテナ内のアプリのトップ・ディレクトリにマウントされるようになります。これによりホスト上のソースの変更が即座にコンテナ内のサーバに反映されるようになっています。

### A-1. ビルド、コンテナ起動

これによりコンテナ内で /bin/sh が起動しますが、これはコンテナを維持するためだけのものです。
Rails サーバーは起動しませんので、その後に述べるようにコンテナ内で操作してください。

```
$ docker compose up --build
```

### A-2. Rails コマンドを実行

実行に必要な設定は環境変数から設定します。起動の前に設定してください。最低限の設定内容はビルド時に設定されています。詳しくは [/docs/ENVIRONMENT_VARIABLES.ja.md](/docs/ENVIRONMENT_VARIABLES.ja.md) を参照してください。

Rails に関するコマンドはコンテナ内で実行します。以下の例では、ホスト側のシェルから `docker compose exec web ...` を使って実行しています。

初回は、データベースのセットアップと CSS の最初のビルドを行ってください。

```
$ docker compose exec web bin/rails db:prepare
$ docker compose exec web bin/rails tailwindcss:build
```

その後は開発状況に応じて、サーバーの起動やマイグレーションなど、任意の Rails コマンドをコンテナ内で実行します。

```
# サーバー起動
$ docker compose exec web bin/rails s -b 0.0.0.0 -p 3000
```

```
# マイグレーションなどの Rails コマンド
$ docker compose exec web bin/rails db:migrate
```

データベースは Docker ボリューム内に配置されているため、 SQLite コマンドはコンテナ内から実行する必要があります。コマンドラインから操作したい場合は、次のワンショット実行を使ってください。

```
$ docker compose run --rm sqlite /rails/storage/development.sqlite3
```

またデータベースを Web UI で操作したい場合は、 `sqlite-web` を利用できます。コンテナを起動し、ブラウザで `8080` ポートにアクセスしてください。

```
$ docker compose --profile tools up sqlite-web
```

### A-3. ホスト上のブラウザでアクセス

```
# アプリケーション
http://127.0.0.1:3000/

# MailCatcher Web UI
http://127.0.0.1:1080/
```

### A-4. VNC 経由の GUI ブラウザ（オプション）

System spec のデバッグや手元での GUI 確認が必要な場合は、コンテナ内に Chromium と VNC を追加インストールして利用できます。詳細手順は次を参照してください。

- [/docs/SETUP_BROWSER.ja.md](/docs/SETUP_BROWSER.ja.md)
- [/docs/SETUP_VNC.ja.md](/docs/SETUP_VNC.ja.md)

## (B) Docker を使わずに構築する

### B-1. データベースのセットアップ

最初に、データベースをセットアップしてください。

```
$ bin/rails db:prepare
```

### B-2. 環境変数

アプリケーションを動作させるために、[/docs/ENVIRONMENT_VARIABLES.ja.md](/docs/ENVIRONMENT_VARIABLES.ja.md) に記載されている環境変数を設定してください。

### B-3. 実行

全ての設定が完了したら、Web サーバを以下のコマンドで起動してください。

```
$ bin/rails s -b 0.0.0.0 -p 3000
```

その後、ブラウザでトップページにアクセスします。

## 管理者ユーザのパスワード変更

データベース初期化時、seed データの投入により `users` テーブルに管理者ユーザが作成されます。管理者ユーザのパスワードは Rails コンソールなどから変更してください。

```
$ bin/rails c
> user = User.admin_user
> user.password = 'YOU MUST CHANGE THIS!'
> user.save!
```

注意：現時点ではパスワード以外の値は変更しないでください。

## Tailwind CSS のビルド

このプロジェクトの CSS には Tailwind を使用しています。CSS ファイルのビルドが必要なため、サーバーの最初の起動の前に、いちど次のコマンドを実行してください。

```
$ bin/rails tailwindcss:build
```

そして、CSS の変更のたびに、ビルドが必要です。したがって開発中は、Tailwind CSS の自動ビルドのために `bin/rails tailwindcss:watch` を同時に実行しておくと便利です。また、複数のプロセスを同時に起動するために `bin/dev` も利用可能です。

-----

# カスタマイズ・ガイド

このアプリをベースに独自に拡張される場合は、本セクションを参考ガイドとしてご活用ください。

## プロジェクト構成

本プロジェクトは Ruby on Rails の標準的なディレクトリ構成および慣習に従っています。新しい機能の追加やカスタマイズを行う場合は、コントローラ・モデル・ビュー・設定など、Rails の流儀に従って実装してください。

標準から外れる独自の部分が今後追加された場合は、このセクションに追記していく予定です。

## 国際化（ロケール）

[Rails ガイドの国際化のセクション](https://railsguides.jp/i18n.html) に基づき設定しています。リクエストごとのロケールの設定については URL パラメータを採用し、ルーティングでロケールを必須としています。

```
scope ":locale", locale: /en|ja/ do
  ...
```

デフォルトのロケールは `en` です。

また訳文については `en` と `ja` が用意されています。項目を追加した際はいずれの訳文についても更新してください。

デフォルトロケールに対して、ほかの言語の訳文の項目が足りているか、または余分があるかをチェックするツールを rake タスクとして作ってあります。

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

ロケール周りの実装については、[/docs/LOCALE_SYSTEM_DESCRIPTION.ja.md](/docs/LOCALE_SYSTEM_DESCRIPTION.ja.md) に説明をまとめていますので、そちらを参照してください。

## フラッシュ・メッセージ

フラッシュ・メッセージについては、gem `flash_unified` を使用しています。この gem は、このプロジェクトで実験的に実装したものを切り出して gem として整えたものです。

くわしくは gem のプロジェクト・ページ [https://github.com/hiroaki/flash-unified](https://github.com/hiroaki/flash-unified) を参照してください。

## テスト

RSpec のテストが用意されています。Capybara の `javascript_driver` に cuprite を使用しているため、テスト実行環境に Google Chrome ブラウザが必要です。

```
$ bin/rspec
```

OAuth (GitHub) に関するテストについては、その機能を有効化した場合と無効化した場合のコンテキストを同時にテストすることができません。Rails の初期化の段階で有効・無効が確定し、セットアップされるためです。したがって RSpec のテストを二回に分けて、別々のプロセスで行う必要があります。

OAuth が有効なコンテキストのテストは通常の RSpec として実行してください。OAuth が無効なコンテキストのテストは、環境変数 `RSPEC_DISABLE_OAUTH_GITHUB` に `1` をセットし、実行対象としてディレクトリ `spec/system/oauth_github_disabled/` を指定して実行します。全ての spec ファイルに対して実行しても構いませんが、現時点では `spec/system/oauth_github_disabled/` に置かれたテストだけが、OAuth が無効なコンテキストのテストになっています。

```
$ RSPEC_DISABLE_OAUTH_GITHUB=1 bin/rspec spec/system/oauth_github_disabled/
```

このコンテキストが影響するテストを作成する場合は、そのブロックにタグ `oauth_github_required` と `oauth_github_disabled` を付けてください。前者のタグを付けたブロック内は OAuth が有効化されている条件下でのテストとし、タグ `oauth_github_disabled` がついたテストはスキップされます。逆の場合も同様です。

RSpec を実行すると、SimpleCov によるカバレッジ・レポートが `coverage/index.html` として出力されるので、結果をご覧ください。なお上述した `RSPEC_DISABLE_OAUTH_GITHUB` による二回に分けたテストスイートのカバレッジは、連続して実行することで自動的にマージされます。

system spec でのデバッグのためにブラウザでの実行の様子を見たい場合は、RSpec 実行時に環境変数 `HEADLESS` に `0` を指定するとヘッドレス・モードを解除できます。また環境変数 `SLOWMO` に数値を指定すると、操作のステップごとにその秒数のディレイが入ります。コード上で止めたい場所に `binding.pry` などを挟んでおき、次のように実行するとよいでしょう。

```
$ HEADLESS=0 SLOWMO=0.5 bin/rspec ./spec/system/something_spec.rb:123
```

このアイデアは [Rails: SeleniumをCupriteにアップグレードする（翻訳）](https://techracho.bpsinc.jp/hachi8833/2023_10_16/133982) から頂きました。ありがとうございます。