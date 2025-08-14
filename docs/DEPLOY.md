# Deploy / デプロイ

Deployment environments can vary greatly depending on the user, so it is not possible to provide a universal, step-by-step guide. However, this project includes Kamal (installed via Bundler) as a deployment tool, and you can use Kamal for deployment.

デプロイ環境は利用者によって様々に異なるため、汎用的で明確な手順を作成することができません。ただしプロジェクトには、デプロイツールとして Kamal が（ Bundler によって）インストールされており、デプロイは Kamal を使用することができます。

## Dockerfile

The Dockerfile located at the top level of the project is intended for both staging and production environments. You can use it to build Docker images for deployment. Please note that this Dockerfile is designed for the environment described in the "Configuration" section below. If your requirements differ, feel free to customize it as needed.

プロジェクトのトップディレクトリにある Dockerfile は、ステージング環境およびプロダクション環境のためのものです。これを用いてデプロイ用の Docker イメージを作成することができます。ただしこれは、以下の「Kamal でステージング環境を構築する」の「構成」で述べている環境を前提として設計されていますので、それとは異なるニーズが要求される部分については適宜カスタマイズしてください。

**Note:**
When building this Dockerfile, you must specify the `RAILS_ENV` build argument as either "staging" or "production". This argument is not automatically set from your environment variables, so be sure to specify it explicitly as shown below:

また注意事項として、この Dockerfile のビルドには `--build-arg` の引数に `RAILS_ENV` が必須となっており、これに "staging" または "production" をセットしてビルドする必要があります。この引数の `RAILS_ENV` はあくまで引数の名称であり、ユーザの環境変数に `RAILS_ENV` （これは環境変数の変数名）が設定されていても、それが暗黙のうちに使われるわけではありません。もちろん環境変数を参照させて `--build-arg RAILS_ENV=$RAILS_ENV` という書き方もできますが、事故を未然に防ぐために文字列で指定してください、次のように：

```
# Production
$ docker build --build-arg RAILS_ENV=production -t annabelle-production:latest .
```

```
# Staging
$ docker build --build-arg RAILS_ENV=staging -t annabelle-staging:latest .
```

**Important:**
The build context will include all files in the current directory, including files not tracked by git. Be careful not to include any sensitive information in your image.

**重要:**
コンテナのビルドではカレント・ディレクトリが COPY されるので、 git 管理外のファイルが混じっていてもそれらはイメージに含まれます。秘匿情報が入り込まないように注意してください。

---

# Example: Deploying a Staging Environment with Kamal / Kamal でステージング環境を構築する

Below is an example procedure for deploying to a staging environment using Kamal.

Kamal によるステージング環境へのデプロイ手順の一例を紹介します。

## Configuration / 構成

This example assumes the following architecture:

これから紹介する例では、次のような構成を前提とします。

```
                   User (developer)
......................................................
   |        |                                     |
   |        | access                              |
   |        v                                     |
   |        443                                   |
   |    +-----------+                             |
   |    |kamal-proxy|                             |
   |    +-----------+                             |
   |        |                                     | access
   |        |forward                              |
   |        v                                     v
   |       3001                                  1080
   |   +----------------+                    +-----------+
   |   |thruster + Rails|---["kamal"]--> 1025|MailCatcher|
   |   +----------------+    Network         +-----------+
   |        ^                                     ^
   |        | pull                                | pull    LAN
~~~|~~~~~~~~|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|~~~~~~~~~~~~~~~~~
   v push   |                                     |         Internet
 +------------------------+               +--------------+
 |    Container Registry  |               | Docker Hub   |
 +------------------------+               +--------------+
```

- The "User" represents a developer who tests the staging environment and performs deployments and service access.
- The entry point is `kamal-proxy`, which also acts as the SSL terminator (port 443).
- The application server uses `thruster` as a wrapper for Puma, listening on port 3001.
- Mail sent from Rails is handled by MailCatcher (SMTP), with communication over the internal Docker network "kamal".
- The MailCatcher web interface is exposed directly on port 1080, without passing through the proxy.
- In this staging setup, all roles are deployed on a single host, even though the diagram shows them separately.

- User はステージング環境をテストする開発者を表します。ここからデプロイ、およびサービスの利用を行います。
- kamal-proxy をエントリーポイントとし、また SSL終端 として位置付けます。ポート番号は 443 とします。
- アプリケーションサーバは puma のラッパーとなる thruster を利用します。ポート番号は 3001 とします。
- Rails からのメールを処理する SMTP サーバーには MailCatcher を利用し、その間の通信は Docker の内部ネットワーク "kamal" を利用します。
- MailCatcher の Web インターフェースは、 Proxy を通さずに、そのまま 1080番 ポートで公開します。
- 各役割のサーバーについて、ステージング環境ではすべて同じホストにデプロイします。上の図では別々に描かれていますが、実際は一つのホスト内にあります。

  ```
    proxy.ssl.host = servers.web.host = accessories.host
    +----------------------------------------------------+
    | +-----------+   +----------------+   +-----------+ |
    | |kamal-proxy|   |thruster + Rails|   |MailCatcher| |
    | +-----------+   +----------------+   +-----------+ |
    +----------------------------------------------------+
  ```

## Docker Engine on the Target Host / デプロイ先の Docker エンジン

This example assumes that Docker Engine is already running on the target server.

この例では、デプロイ先サーバーでは Docker エンジンがすでに稼働している状態を前提としてます。

Kamal can install Docker automatically, but this requires logging in as the `root` user via SSH, and continued root access. In this example, the SSH user for deployment is specified via the `DEPLOY_SSH_USER` environment variable and is assumed to be a regular user.

Kamal には Docker 自体を自動でインストールする機能もありますが、それを利用するにはデプロイ先へログインする SSH ユーザとして `root` を設定しなければならなくなり、その後も継続して root ユーザでのアセクスが必要になってしまいます。今回の例では、デプロイ先へ SSH 接続するユーザは、この例の設定としては環境変数 `DEPLOY_SSH_USER` に設定するユーザです。これは一般ユーザを想定しています。

To allow a regular user to create Docker containers, ensure that the user belongs to the `docker` group. If not, add the user as follows:

一般ユーザが Docker コンテナを作成するには、そのユーザーがグループ `docker` に属している必要がありますので、その状況を確認してください。まだグループに属していなければ、次のようにして参加させることができます：

```sh
$ sudo usermod -aG docker <username>
```

If Docker Engine is not yet installed, you can install it as shown below (example for Rocky Linux 9). Note: Rootless mode is untested; please perform the installation as a privileged user.

Docker エンジンがまだインストールされていない場合は、次のようにインストールできます。なお Docker の Rootless モードは未検証ですので、インストールそのものは特権ユーザで行ってください：

```sh
# Example for Rocky Linux 9
$ sudo dnf install -y dnf-plugins-core
$ sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
$ sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
$ sudo systemctl enable --now docker
```

## Persistent Volumes / 永続化ボリューム

You need to create a directory to be used as a volume for the application’s Docker container, and set its path in the `DEPLOY_VOLUMES_STORAGE` environment variable.

アプリケーションの Docker コンテナにマウントするボリュームとして、任意のディレクトリを環境変数 `DEPLOY_VOLUMES_STORAGE` にて設定することになりますが、そのディレクトリを作成してください。

```sh
$ mkdir $HOME/data
```

This directory must be created before the first deployment. If you forget to create it, the application may fail to start after deployment. In that case, please check that the application has write permissions to the directory and adjust the permissions if necessary.

このディレクトリは最初のデプロイの前に作成しなければいけません。もし後になってしまった場合は、おそらく、デプロイ後のアプリケーションの起動に失敗するかもしれません。その場合はディレクトリにアプリケーションが書き込みできる権限があるか、パーミッションを確認してください。

## config/deploy.yml

The Kamal configuration file `config/deploy.yml` contains only the setting `require_destination: true`. This indicates that a separate configuration file is required for each deployment target, and you must specify the destination when running Kamal.

Kamal の設定ファイルである `config/deploy.yml` にはただ一つの記述 `require_destination: true` という設定だけがあります。これはデプロイ先に応じた別の設定ファイルの存在を暗示しており、実行時にはそのデプロイ先を指定する必要があることを設定しています。

For staging, a sample file `config/deploy.staging.yml.sample` is provided. Copy it to `config/deploy.staging.yml` and customize as needed.

デプロイ先がステージング環境用のものは、サンプルとしてファイル `config/deploy.staging.yml.sample` が用意されていますので、これを `config/deploy.staging.yml` という名のファイルに複製し、これをカスタムしてください。

In this example configuration, no changes are required. All values to be changed are read from environment variables, which are described later.

いま説明している例の構成においては、何も変更する箇所はありません。変更するべきすべての値は環境変数から読み取るようになっています。設定する必要がある環境変数については後述します。

## .kamal/secrets

Sensitive information referenced in `config/deploy.staging.yml` is managed separately in `.kamal/secrets`. There is also a separate secrets file for each deployment target; for staging, use `.kamal/secrets.staging`.

ファイル `config/deploy.staging.yml` の記述の中で秘匿情報にあたる部分は、別管理のファイル `.kamal/secrets` があります。そしてこれもまた、 Kamal のデプロイ先に応じた別のファイルがあります。この例ではステージング環境であるので、ここでは `.kamal/secrets.staging` がその扱うべき対象のファイルとなります。

If you have not modified `config/deploy.staging.yml`, you do not need to change `.kamal/secrets.staging` either. All values are read from environment variables.

前項で述べた設定ファイル `config/deploy.staging.yml` を変更していないのであれば、 `.kamal/secrets.staging` についても修正箇所はありません。変更するべきすべての値は、環境変数から読み取るようになっています。

## Container Registry / コンテナ・レジストリ

With Kamal, images built on the deployment source are pushed to a container registry.

Kamal のコンセプトにより、デプロイ元でビルドされたイメージは、コンテナー・レジストリへ push されることになります。

This registry is an internet service (such as Docker Hub or GitHub). You will need an account with permission to push images.

このレジストリはインターネット上のサービスになります（ Docker や GitHub など）。そのためにそれらのサービスにコンテナを push するためのアカウント（アクセス権）が必要です。

## SSL (TLS) Certificates and hosts File / SSL (TSL) 証明書と hosts ファイル

Kamal can automatically generate and renew certificates using Let's Encrypt. However, for a LAN-based staging environment, this example uses `mkcert` to create a local root CA, which must be installed on both the user's and the deployment target's environments.

SSL(TSL) のサーバー証明書については、 Kamal では Let's Encrypt （外部サービス）を利用した証明書の作成（更新）を自動で行う機能がありますが、この例では LAN 内に構築するステージング環境という都合から、 mkcert を利用した自前のルート認証局をあらかじめ作成し、そのルート証明書を User の環境およびデプロイ先の環境にインストールしておくことになります。

The Common Name (hostname) must be resolvable, so register it in `/etc/hosts` if necessary. If you have a DNS server for your LAN, that is also sufficient.

またその際、 Common Name となるホスト名が解決できなければいけないため、 `/etc/hosts` ファイルにホスト名を登録しておきます（もし LAN 内のアドレスを解決できる DNS が利用できるのであれば、それで十分です）

## Environment Variables / 環境変数の設定

Set the required environment variables for application and deployment configuration.

アプリケーション設定や、デプロイ設定のために必要な、環境変数を設定します。

For details on application and deployment environment variables, see [/docs/ENVIRONMENT_VARIABLES.md](/docs/ENVIRONMENT_VARIABLES.md).

アプリケーション設定のための環境変数、およびデプロイ設定のための環境変数については [/docs/ENVIRONMENT_VARIABLES.md](/docs/ENVIRONMENT_VARIABLES.md) を参照してください。

## Running the Deployment / デプロイの実行

After setting the environment variables in your shell, deploy with the following command:

シェルに環境変数をセットしたのち、次のコマンドでデプロイします。

```
$ bundle exec kamal deploy --destination=staging
```

If you are using dotenv, you can specify the `.env.staging` file as follows:

dotenv を使って環境変数を設定しながら実行する場合は、ファイル `.env.staging` を指定しながら実行します：

```
$ dotenv -f .env.staging bundle exec kamal deploy --destination=staging
```

If your directory is not under git control, specify the version with the `--version ...` option:

ディレクトリが Git 管理下にない場合は、 `--version ...` オプションを用いてバージョンを指定してください：

```
$ dotenv -f .env.staging bundle exec kamal deploy --destination=staging --version=12345
```
