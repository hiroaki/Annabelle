# Environment Variables / 環境変数

Annabelle uses two main categories of environment variables: those related to application behavior, and those related to deployment. For development and test environments, deployment-related variables are not required and can be ignored. Alternatively, if you create your own Kamal deployment configuration, you do not need to use the deployment-related environment variables described here.

Annabelle が利用する環境変数は、大きく分けて二種類のカテゴリに属します。アプリケーションの動作に関するものと、デプロイに関するものです。アプリケーションの構築対象が development および test 環境においてはデプロイしませんので、それら環境に於いてはデプロイに関する環境変数は無視して構いません。また、 Kamal のデプロイ設定を独自に作成する場合も、ここで説明するデプロイに関する環境変数は不要です。

If you are using dotenv, please rename one of the sample files and use it as your environment file. There are three sample `.env` files provided for production, staging, and development environments. These are not generic templates, but rather starting points. Please review the explanations for each environment variable below and set the values as needed:

| File Name         | Purpose / Description |
|-------------------|-----------------------|
| dot.env.development.sample  | Sample for development. No deployment-related environment variables are included. |
| dot.env.staging.sample      | Intended for building a staging environment. Contains the variables needed for the configuration described in DEPLOY.md and pairs with config/deploy.staging.yml. |
| dot.env.production.sample   | Intended for production use. It is almost the same as the staging sample, except for the proxy.ssl settings. Use it as a reference. |

dotenv を利用する場合は、サンプルのファイルを、リネームして利用してください。サンプルの `.env` は、 production / staging / development それぞれの環境用の３つがありますが、いずれも汎用的なものではなく、あくまで雛形です。以降に述べていく各環境変数の説明を確認の上、必要な値を設定してください：

| ファイル名         | 用途・説明 |
|------------------|-----------|
| dot.env.development.sample | 開発用のサンプルです。デプロイ用の環境変数はありません。 |
| dot.env.staging.sample     | ステージング環境の構築用。DEPLOY.mdに記載の構成を実現するために必要な変数を含み、config/deploy.staging.ymlとペアです。|
| dot.env.production.sample  | 本番環境用のサンプル。ステージング用とほぼ同じですが、proxy.sslの設定が異なります。参考としてご利用ください。 |

**Important:**
Many of the environment variables described below contain sensitive information (such as passwords, encryption keys, and API secrets). Never commit them to your repository or share them publicly.

**重要:**
以下で設定する多くの環境変数はパスワードや暗号化キー、APIシークレットなどの機密情報を含みます。絶対にリポジトリにコミットしたり、外部に漏らさないよう注意してください。

## Application Settings / アプリケーション設定

These environment variables control application behavior.

アプリケーションの動作に関する環境変数です。

### SMTP settings / SMTP 設定

Set the following variables for SMTP configuration:

SMTP サーバ設定のため、以下の変数を設定してください：

```
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_DOMAIN=example.com
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
```

In development or staging environments, you may leave `SMTP_USERNAME` and `SMTP_PASSWORD` empty if they are not required.

開発環境やステージング環境などで、 `SMTP_USERNAME` や `SMTP_PASSWORD` など不要な項目は空のままでも問題ありません。

### Mailer Settings / メール設定

User login and registration are implemented using the devise (gem). Set the sender email address for emails sent from devise.

ログインやユーザ登録は devise (gem) で実装されていますが、 devise から送信されるメールの送信者のメールアドレスを設定してください。

```
DEVISE_MAILER_SENDER=admin@example.com
```

### App Host / アプリケーション・ホスト

These variables are also used to indicate the application's location in outgoing emails.

これらの変数は、送信されるメール本文中にアプリケーションのロケーションを示すために利用されます。

```
APP_HTTP_HOST=www.example.com
APP_HTTP_PORT=443
APP_HTTP_PROTOCOL=https
```

### SECRET_KEY_BASE

Required in production and staging environments. SECRET_KEY_BASE is used for encrypting sessions, cookies, and other sensitive data. Once set, DO NOT change this key as it will invalidate all existing sessions and encrypted data

本番およびステージング環境で必須です。SECRET_KEY_BASE はセッションやクッキー、その他の機密データの暗号化に使われます。設定した後に変更すると、既存のセッションや暗号化済みデータが復号できなくなるため、決して変更しないでください。

Use a sufficiently long random string for security — for example, 64 hexadecimal characters (256 bits) or a 32‑byte base64 string. Generate one with the command below:

安全な値は十分な長さのランダム文字列（例：256ビット相当の 64 hex 文字 / 32 バイトの base64 等）です。次のコマンドで生成できます：

```bash
$ bin/rails secret
7f1bbba9cbbd1999fd641b80861ac989807eb8fbdd...
$
```

生成した値をセットしてください。

```
SECRET_KEY_BASE=7f1bbba9cbbd1999fd641b80861ac989807eb8fbdd...
```

### Two-Factor Authentication / 二要素認証

Set this variable to enable two-factor authentication.
If you enable two-factor authentication, you must also set the Active Record encryption variables described in the next section.

二要素認証を利用する場合にセットしてください。また、二要素認証を利用する場合は次の Active Record 暗号化の設定も必要になりますので、併せてセットしてください。

```
ENABLE_2FA=1
```

### Active Record Encryption / Active Record 暗号化

Active Record encryption configuration is required for the two-factor authentication implementation. These values can be generated using `bin/rails db:encryption:init`, and you should copy the strings output to the screen and set them to these environment variables:

Active Record 暗号化の設定で、二要素認証の実装のために必要です。これらの値は `bin/rails db:encryption:init` で生成することができ、画面に出力された文字列をコピーして、これらの環境変数に設定してください：

```
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=1a2b3c4d5e6f7g8h9i0j...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=0j9i8h7g6f5e4d3c2b1a...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=abcdef1234567890...
```

### OAuth (GitHub authentication) / OAuth (GitHub 認証)

To use GitHub OAuth authentication, you first need to create an OAuth App for your project on GitHub. You will be asked to enter a callback URL path; for development environments, use the following path (replace the hostname and port as appropriate for your environment):

GitHub OAuth 認証を利用するには、まず GitHub 上でこのプロジェクト用の OAuth アプリを作成してください。その際にコールバック URL のパスを入力する必要がありますが、開発環境に於いては次のパスになります（ホスト名やポート番号は環境に応じて置き換えてください）：

```
http://127.0.0.1:3000/users/auth/github/callback
```

After creating the app, set the following variables using the Client ID and Client Secret provided by GitHub. These credentials allow your application to authenticate users via GitHub:

アプリ作成後、 GitHub から発行される Client ID と Client Secret をこれらの変数に設定してください：

```
GITHUB_CLIENT_ID=Ov23abcde...
GITHUB_CLIENT_SECRET=abcdef0123456789abcdef...
```

### Client-side Request Size Limit / リクエストのサイズ制限（クライアント側）

This application does not enforce request size limits internally; instead, it assumes that such limits are handled by the proxy server.

クライアントからのリクエストのサイズ制限については、このアプリケーションの内部では制限しておらず、プロキシサーバによって制限を設ける前提にしています。

However, to provide immediate feedback to users before a request is actually sent, the client performs a size check when submitting forms. Set the maximum allowed size (in bytes) for this client-side check.

しかしながら実際のリクエストが発生する前の段階でユーザへエラーを返すために、ユーザがフォームを送信する際に、クラアント側でのチェックを行います。そのときのサイズ上限値（バイト）を設定してください。

This value should match `DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY`, but for safety, set it slightly lower to allow for some margin.

この値は `DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY` と同じ値にします。ただ、マージンを考慮して、それよりも少し小さな値にしてください。

```
MAX_REQUEST_BODY=10485760
```

### Basic Authentication / Basic 認証

Setting these values enables Basic Authentication.

これらの値を設定すると、 Basic 認証 を有効にします。

```
BASIC_AUTH_USER=guest
BASIC_AUTH_PASSWORD=annabelle
```

### Image Processing Backend / 画像処理バックエンド

This project uses the image_processing gem for Active Storage image and video processing.

このプロジェクトでは、Active Storage の画像・動画処理に image_processing (gem) を使用しています。

For development environments, ImageMagick is used by default to improve compatibility with older operating systems and setups. You must have ImageMagick installed on your system.
If you want to use libvips instead, install libvips and set the environment variable `ANNABELLE_VARIANT_PROCESSOR` to `vips` before starting the application.

開発環境に於いては、古い OS や環境との互換性向上のため、デフォルトで ImageMagick を使用しています。システムに ImageMagick がインストールされている必要があります。libvips を利用したい場合は、libvips をインストールして、アプリケーション起動前に環境変数 `ANNABELLE_VARIANT_PROCESSOR` を `vips` に設定してください。

In production and staging environments, vips is installed during the Docker build process. Therefore, set `ANNABELLE_VARIANT_PROCESSOR` to `vips` at deployment time. The sample `config/deploy.staging.yml.sample` and `config/deploy.production.yml.sample` files already include this setting.

本番環境およびステージング環境は Docker 構築時に vips がインストールされます。そのためデプロイ時に `ANNABELLE_VARIANT_PROCESSOR` を `vips` に設定してください。サンプルの `config/deploy.staging.yml.sample` および `config/deploy.production.yml.sample` には、その設定があらかじめ記述されています。

```
ANNABELLE_VARIANT_PROCESSOR=vips
```

## Deployment Settings / デプロイ設定

This section explains the environment variables you need to set when using the sample Kamal configuration files (`config/deploy.*.yml.sample`) for actual deployment.

ここでは、 Kamal の設定ファイルのサンプル `config/deploy.*.yml.sample` を実際のデプロイに使う場合に、設定する必要がある環境変数を説明します。

Since deployment environments can vary greatly depending on the user, this project provides a sample Kamal configuration file for a specific deployment scenario. The sample is designed to be configured using the environment variables described below.

デプロイ先の環境は利用者によって様々に異なるため、このプロジェクトではあるひとつのデプロイ先環境を想定し、そのための Kamal 設定ファイルをサンプルとして用意しています。そのサンプルは以下に説明していく環境変数を通して Kamal の設定を行うようになっています。

If your deployment environment differs from this example, feel free to create your own Kamal configuration file tailored to your environment. In that case, the environment variables described below are not required; you can specify the values directly in your Kamal configuration file.

一方、デプロイ先の環境がそれとは異なっている場合は、実際のデプロイ先の状況に応じた Kamal の設定ファイルを任意に作成してください。その場合は以下に説明していく環境変数は不要なものです（それらの値は、直接 Kamal 設定ファイルに記述していけばよいでしょう）。

All deployment-related environment variables are prefixed with "DEPLOY_".

なお、デプロイ設定に関する環境変数の名前は、接頭語として "DEPLOY_" がついています。

**Important:**
Many of the environment variables described below contain sensitive information (such as passwords, encryption keys, and API secrets). Never commit them to your repository or share them publicly.

**重要:**
以下で設定する多くの環境変数はパスワードや暗号化キー、APIシークレットなどの機密情報を含みます。絶対にリポジトリにコミットしたり、外部に漏らさないよう注意してください。

### Container Registry Settings / コンテナ・レジストリの設定

With Kamal, the built Docker image is pushed to a container registry. You will need write access to the container registry, so please set the account information accordingly.

Kamal では、ビルドした Docker イメージはいちどコンテナ・レジストリへ push されます。そのためコンテナ・レジストリへの書き込み権限が必要で、そのアカウント情報を設定してください。

The password is typically a personal access token or an access token issued by the registry service.

パスワードには、通常レジストリサービスで発行されたパーソナルアクセストークンやアクセストークンを入力します。

```
DEPLOY_REGISTRY_SERVER=ghcr.io
DEPLOY_REGISTRY_USERNAME=yourname
DEPLOY_REGISTRY_PASSWORD=abcdefghijklmnopqrstuvwxyz_0123456789ABC
```

### Docker Image Name / Docker イメージ名

Specify the name to use for the image when uploading it to the container registry.

この名称でイメージがコンテナ・レジストリにアップロードされます。

```
DEPLOY_IMAGE=yourname/annabelle-production
```

### Deployment Hosts / デプロイ先ホスト

Specify a comma-separated list of hosts where the application will be deployed.

アプリケーションをデプロイする先のホストのリストです（カンマ区切り）。

```
DEPLOY_SERVERS_WEB_HOSTS="www1.example.com"
```

### SSH Settings / SSH 設定

These settings are used to log in to the deployment target hosts via SSH. The specified user must belong to the `docker` group on the target host. See [/docs/deploy.md](/docs/deploy.md) for details. `DEPLOY_SSH_KEYS` is a comma-separated list of private key file paths used for public key or host-based authentication.

デプロイ先ホストへ SSH でログインするための設定です。このユーザはデプロイ先のホストのグループ `docker` に属している必要があります。 [/docs/deploy.md](/docs/deploy.md) を参照してください。 `DEPLOY_SSH_KEYS` は、公開鍵認証やホストベース認証に使用する秘密鍵ファイル名のリストです（カンマ区切り）。

```
DEPLOY_SSH_PORT=22
DEPLOY_SSH_USER=operator
DEPLOY_SSH_KEYS="/home/operator/.ssh/id_rsa"
```

### Persistent Volumes / 永続化ボリューム

Specify the directory on the deployment host to be mounted as a volume in the Docker container.
Annabelle stores both the SQLite3 database file and user-uploaded files in this directory.

デプロイ先の Docker コンテナにマウントされる、ボリュームとして指定されるディレクトリを指定します。 Annabelle では SQLite3 のデータベース・ファイルと、ユーザがアップロードしたファイルが保存されます。

```
DEPLOY_VOLUMES_STORAGE=/home/operator/data
```

To back up your data, simply back up this directory.

データのバックアップは、このディレクトリをバックアップしてください。

### Proxy Seggings / プロキシ設定

Set `DEPLOY_PROXY_HOST` to the host where kamal-proxy is deployed. This value should be specified as the domain name that matches the Common Name (CN) in your SSL/TLS server certificate.

`DEPLOY_PROXY_HOST` は kamal-proxy が配置されるホストを指定します。この値は SSL/TLS サーバ証明書の CN に相当するドメイン名で指定します。

```
DEPLOY_PROXY_HOST=www.example.com
```

`DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY` sets the maximum request size (in bytes) allowed by the proxy. If a request exceeds this size, the proxy will return HTTP status 413 and the request will not reach the application. The value of `MAX_REQUEST_BODY` mentioned earlier should be based on this value.

`DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY` はプロキシが制限する、リクエストの最大サイズ（バイト）です。これを超える場合、プロキシは HTTP ステータス 413 を返し、リクエストはアプリケーションへは到達しません。また前述の `MAX_REQUEST_BODY` の値は、この値をベースにします。

```
DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY=10485760
```

To use a custom SSL/TLS certificate, set the contents of the PEM-formatted certificate and private key directly in the corresponding environment variables.

SSL/TLS カスタム証明書を使用する場合は、 pem 形式の証明書・秘密鍵の内容を、そのまま環境変数に設定してください。

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

### MailCatcher Host / MailCatcher ホスト

In the sample configuration for staging deployment, MailCatcher is set up as the SMTP service. MailCatcher is also configured to be deployed as an accessory with Kamal, so you need to specify the address of the host where MailCatcher will be deployed.

ステージング環境へのデプロイのサンプルでは、 SMTP サービスに MailCatcher を使用するように設定されています。また MailCatcher はアクセサリとして Kamal にデプロイされるように設定されているため、 MailCatcher のデプロイ先のホストのアドレスが必要です。

```
DEPLOY_ACCESSORIES_MAILCATCHER_HOST=
```
