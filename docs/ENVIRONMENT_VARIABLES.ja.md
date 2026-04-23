[English version is here](ENVIRONMENT_VARIABLES.md)

# 環境変数

Annabelle が利用する環境変数は、大きく分けて二種類のカテゴリに属します。アプリケーションの動作に関するものと、デプロイに関するものです。development および test 環境ではデプロイに関する環境変数は不要なので無視して構いません。また、Kamal のデプロイ設定を独自に作成する場合も、ここで説明するデプロイに関する環境変数は不要です。

dotenv を利用する場合は、サンプルのファイルをリネームして利用してください。production、staging、development それぞれの環境用に 3 つのサンプル `.env` ファイルがありますが、いずれも汎用テンプレートではなく、あくまで雛形です。以下に述べる各環境変数の説明を確認の上、必要な値を設定してください。

| ファイル名 | 用途・説明 |
|---|---|
| dot.env.development.sample | 開発用のサンプルです。デプロイ用の環境変数はありません。 |
| dot.env.staging.sample | ステージング環境の構築用です。DEPLOY.ja.md に記載の構成を実現するために必要な変数を含み、`config/deploy.staging.yml` と組み合わせて使います。 |
| dot.env.production.sample | 本番環境用のサンプルです。ステージング用とほぼ同じですが、`proxy.ssl` の設定が異なります。参考として利用してください。 |

**重要:**
以下で設定する多くの環境変数は、パスワードや暗号化キー、API シークレットなどの機密情報を含みます。絶対にリポジトリにコミットしたり、外部に漏らしたりしないでください。

## アプリケーション設定

これらはアプリケーションの動作に関する環境変数です。

### SMTP 設定

SMTP サーバ設定のため、以下の変数を設定してください。

```
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_DOMAIN=example.com
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
```

開発環境やステージング環境などでは、`SMTP_USERNAME` や `SMTP_PASSWORD` など不要な項目は空のままでも問題ありません。

### メール設定

ログインやユーザ登録は devise gem で実装されています。devise から送信されるメールの送信者アドレスを設定してください。

```
DEVISE_MAILER_SENDER=admin@example.com
```

### アプリケーション・ホスト

これらの変数は、送信されるメール本文中にアプリケーションのロケーションを示すためにも利用されます。

```
APP_HTTP_HOST=www.example.com
APP_HTTP_PORT=443
APP_HTTP_PROTOCOL=https
```

### SECRET_KEY_BASE

本番およびステージング環境で必須です。`SECRET_KEY_BASE` はセッションやクッキー、その他の機密データの暗号化に使われます。設定した後に変更すると、既存のセッションや暗号化済みデータが復号できなくなるため、変更しないでください。

安全な値としては、十分な長さのランダム文字列を使ってください。たとえば 64 文字の 16 進文字列や、32 バイトの base64 文字列などです。次のコマンドで生成できます。

```bash
$ bin/rails secret
7f1bbba9cbbd1999fd641b80861ac989807eb8fbdd...
$
```

生成した値を次のように設定してください。

```
SECRET_KEY_BASE=7f1bbba9cbbd1999fd641b80861ac989807eb8fbdd...
```

### 二要素認証

二要素認証を利用する場合に設定してください。また、二要素認証を利用する場合は次の Active Record 暗号化の設定も必要になるため、併せて設定してください。

```
ENABLE_2FA=1
```

### Active Record 暗号化

Active Record 暗号化の設定は、二要素認証の実装に必要です。これらの値は `bin/rails db:encryption:init` で生成できます。画面に出力された文字列をコピーして、以下の環境変数に設定してください。

```
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=1a2b3c4d5e6f7g8h9i0j...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=0j9i8h7g6f5e4d3c2b1a...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=abcdef1234567890...
```

### OAuth (GitHub 認証)

GitHub OAuth 認証を利用するには、まず GitHub 上でこのプロジェクト用の OAuth App を作成してください。その際にコールバック URL のパスを入力する必要がありますが、開発環境では次のパスになります。ホスト名やポート番号は環境に応じて置き換えてください。

```
http://127.0.0.1:3000/users/auth/github/callback
```

アプリ作成後、GitHub から発行される Client ID と Client Secret をこれらの変数に設定してください。

```
GITHUB_CLIENT_ID=Ov23abcde...
GITHUB_CLIENT_SECRET=abcdef0123456789abcdef...
```

### リクエストのサイズ制限（クライアント側）

クライアントからのリクエストのサイズ制限については、このアプリケーション内部では制限しておらず、プロキシサーバによって制限を設ける前提にしています。

ただし、実際のリクエストが発生する前の段階でユーザへエラーを返すために、フォーム送信時にクライアント側でサイズチェックを行います。そのときのサイズ上限値をバイト単位で設定してください。

この値は `DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY` を基準にしますが、マージンを考慮して、それより少し小さめの値にしてください。

```
MAX_REQUEST_BODY=10485760
```

### Basic 認証

これらの値を設定すると Basic 認証が有効になります。

```
ENABLED_BASIC_AUTH=1
BASIC_AUTH_PAIRS=guest:annabelle,readonly:readonlypass
```

`ENABLED_BASIC_AUTH` は Basic 認証を有効化するかどうかを制御します。有効化した場合は、認証情報として `BASIC_AUTH_PAIRS` の設定が必要です。

`BASIC_AUTH_PAIRS` はカンマ区切りで複数の `username:password` ペアを指定できます。

### Rack::Attack 設定

これらの変数は、Rack::Attack による任意のアクセス制限や遮断のための設定です。現時点では、本格的な大規模運用向けというより、デモ用途を意識した簡易的な防衛機能として位置づけています。

```
ENABLED_RACK_ATTACK=1
RACK_ATTACK_GET_THROTTLE_LIMIT=300
RACK_ATTACK_WRITE_THROTTLE_LIMIT=60
RACK_ATTACK_THROTTLE_PERIOD_SECONDS=60
RACK_ATTACK_BAN_DURATION_SECONDS=600
```

`ENABLED_RACK_ATTACK` は Rack::Attack 全体の有効・無効を切り替えます。

`RACK_ATTACK_GET_THROTTLE_LIMIT` は、1 つの throttle period の間に、単一 IP から許可する GET / HEAD リクエスト数の上限です。

`RACK_ATTACK_WRITE_THROTTLE_LIMIT` は、1 つの throttle period の間に、単一 IP から許可する GET / HEAD 以外のリクエスト数の上限です。

`RACK_ATTACK_THROTTLE_PERIOD_SECONDS` は、GET 系と write 系の双方で使う制限期間の長さです。

`RACK_ATTACK_BAN_DURATION_SECONDS` は、`/.env` または `/.env.*` へのアクセスを検知したときに適用する ban の長さです。

現在のデフォルト動作は次の通りです。

- GET / HEAD リクエストは IP 単位で制限されます。
- GET / HEAD 以外のリクエストも IP 単位で制限されます。
- `/.env` または `/.env.*` へのアクセスは即座に ban の対象になります。
- ヘルスチェック用の `/up` は GET / HEAD の制限対象から除外されています。

**注意:** 現在の構成では、Rack::Attack の状態は実質的に単一ホスト単位で扱われます。単一ホスト構成では有用ですが、将来的に複数ホストへスケールする場合は、キャッシュ構成を見直し、Redis などの共有可能な外部ストアの利用を検討してください。

### 画像処理バックエンド

このプロジェクトでは、Active Storage の画像・動画処理に `image_processing` gem を使用しています。

開発環境では、古い OS や環境との互換性向上のため、デフォルトで ImageMagick を使用しています。システムに ImageMagick がインストールされている必要があります。libvips を利用したい場合は、libvips をインストールして、アプリケーション起動前に環境変数 `ANNABELLE_VARIANT_PROCESSOR` を `vips` に設定してください。

本番環境およびステージング環境では、Docker 構築時に vips がインストールされます。そのためデプロイ時に `ANNABELLE_VARIANT_PROCESSOR` を `vips` に設定してください。サンプルの `config/deploy.staging.yml.sample` および `config/deploy.production.yml.sample` には、その設定があらかじめ記述されています。

```
ANNABELLE_VARIANT_PROCESSOR=vips
```

## デプロイ設定

ここでは、Kamal の設定ファイルのサンプル `config/deploy.*.yml.sample` を実際のデプロイに使う場合に設定する必要がある環境変数を説明します。

デプロイ先の環境は利用者によって様々に異なるため、このプロジェクトではある 1 つのデプロイ先環境を想定し、そのための Kamal 設定ファイルをサンプルとして用意しています。そのサンプルは、以下に説明する環境変数を通して Kamal の設定を行うようになっています。

一方、デプロイ先の環境がそれとは異なる場合は、実際の状況に応じた Kamal の設定ファイルを任意に作成してください。その場合は以下に説明する環境変数は不要であり、値を直接 Kamal 設定ファイルに記述して構いません。

なお、デプロイ設定に関する環境変数の名前は、接頭語として `DEPLOY_` が付いています。

**重要:**
以下で設定する多くの環境変数は、パスワードや暗号化キー、API シークレットなどの機密情報を含みます。絶対にリポジトリにコミットしたり、外部に漏らしたりしないでください。

### コンテナ・レジストリの設定

Kamal でのデプロイでは、ビルドした Docker イメージはいちどコンテナ・レジストリへ push されます。そのため書き込み可能なコンテナ・レジストリが必要です。

コンテナ・レジストリには、GitHub や Docker Hub などのリモートの外部サービスを利用することもできますが、ホストマシン上の Docker で動くローカルのレジストリを利用することもできます。

ホストマシン上のローカル・レジストリを使う場合は、`localhost` を指定します。これにより、そのローカル・レジストリは Kamal によって自動的に作成されます。

```
DEPLOY_REGISTRY_SERVER=localhost:5555
```

外部のコンテナ・レジストリを利用する場合は、そのアカウント情報を設定してください。パスワードには、レジストリサービスで発行されたパーソナルアクセストークンやアクセストークンを入力します。

```
DEPLOY_REGISTRY_SERVER=ghcr.io
DEPLOY_REGISTRY_USERNAME=yourname
DEPLOY_REGISTRY_PASSWORD=abcdefghijklmnopqrstuvwxyz_0123456789ABC
```

### Docker イメージ名

コンテナ・レジストリにアップロードする際のイメージ名を指定します。

```
DEPLOY_IMAGE=yourname/annabelle-production
```

### デプロイ先ホスト

アプリケーションをデプロイする先のホスト一覧を、カンマ区切りで指定します。

```
DEPLOY_SERVERS_WEB_HOSTS="www1.example.com"
```

### SSH 設定

これらはデプロイ先ホストへ SSH でログインするための設定です。このユーザはデプロイ先ホストの `docker` グループに属している必要があります。詳しくは [/docs/DEPLOY.ja.md](/docs/DEPLOY.ja.md) を参照してください。`DEPLOY_SSH_KEYS` は、公開鍵認証やホストベース認証に使用する秘密鍵ファイルのパス一覧をカンマ区切りで指定します。

```
DEPLOY_SSH_PORT=22
DEPLOY_SSH_USER=operator
DEPLOY_SSH_KEYS="/home/operator/.ssh/id_rsa"
```

### 永続化ボリューム

デプロイ先の Docker コンテナにマウントされるボリュームのディレクトリを指定します。Annabelle では SQLite3 のデータベース・ファイルと、ユーザがアップロードしたファイルがこのディレクトリに保存されます。

```
DEPLOY_VOLUMES_STORAGE=/home/operator/data
```

データのバックアップは、このディレクトリをバックアップしてください。

### プロキシ設定

`DEPLOY_PROXY_HOST` には `kamal-proxy` が配置されるホストを指定します。この値は、SSL/TLS サーバ証明書の Common Name に対応するドメイン名で指定します。

```
DEPLOY_PROXY_HOST=www.example.com
```

`DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY` は、プロキシが制限するリクエストの最大サイズをバイト単位で設定します。これを超える場合、プロキシは HTTP ステータス 413 を返し、リクエストはアプリケーションへ到達しません。前述の `MAX_REQUEST_BODY` の値は、この値をベースにしてください。

```
DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY=10485760
```

SSL/TLS カスタム証明書を使用する場合は、PEM 形式の証明書と秘密鍵の内容を、そのまま対応する環境変数に設定してください。

```
DEPLOY_CERTIFICATE_PEM="-----BEGIN CERTIFICATE-----
...
...
-----END CERTIFICATE-----
"

DEPLOY_PRIVATE_KEY_PEM="-----BEGIN PRIVATE KEY-----
...
...
-----END PRIVATE KEY-----
"
```

### MailCatcher ホスト

ステージング環境向けのサンプル構成では、SMTP サービスに MailCatcher を使用するように設定されています。また MailCatcher はアクセサリとして Kamal にデプロイされるため、MailCatcher のデプロイ先ホストのアドレスを指定する必要があります。

```
DEPLOY_ACCESSORIES_MAILCATCHER_HOST=
```