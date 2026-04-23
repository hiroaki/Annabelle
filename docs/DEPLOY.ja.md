[English version is here](DEPLOY.md)

# デプロイ

デプロイ環境は利用者によって様々に異なるため、汎用的で明確な手順を作成することができません。ただしプロジェクトには、デプロイツールとして Kamal が（ Bundler によって）インストールされており、デプロイは Kamal を使用することができます。

## Dockerfile

プロジェクトのトップディレクトリにある Dockerfile は、ステージング環境およびプロダクション環境のためのものです。これを用いてデプロイ用の Docker イメージを作成することができます。ただしこれは、以下の「Kamal でステージング環境を構築する」の「構成」で述べている環境を前提として設計されていますので、それとは異なるニーズが要求される部分については適宜カスタマイズしてください。

**注意:**
この Dockerfile のビルドには `--build-arg` の引数に `RAILS_ENV` が必須となっており、これに "staging" または "production" をセットしてビルドする必要があります。この引数の `RAILS_ENV` はあくまで引数の名称であり、ユーザの環境変数に `RAILS_ENV` （これは環境変数の変数名）が設定されていても、それが暗黙のうちに使われるわけではありません。もちろん環境変数を参照させて `--build-arg RAILS_ENV=$RAILS_ENV` という書き方もできますが、事故を未然に防ぐために文字列で指定してください、次のように：

```
# Production
$ docker build --build-arg RAILS_ENV=production -t annabelle-production:latest .
```

```
# Staging
$ docker build --build-arg RAILS_ENV=staging -t annabelle-staging:latest .
```

**重要:**
コンテナのビルドではカレント・ディレクトリが COPY されるので、 git 管理外のファイルが混じっていてもそれらはイメージに含まれます。秘匿情報が入り込まないように注意してください。

---

# Kamal でステージング環境を構築する

Kamal によるステージング環境へのデプロイ手順の一例を紹介します。

## 構成

これから紹介する例では、次のような構成を前提とします。

```
                   User (Developer)
==================================================================
      |                    |                       |      Local PC
      v deploy             |                       |
 +------------------+      |                       |
 | kamal            |      |                       |
 | -docker-registry |      |                       |
 +------------------+      |                       |
   |                       |                       |
==[22]===================[443]==================[1080]============
   |                       |                       |       Staging
   |                       v access                |
   | pull       +-------------+                    |
   +----------->| kamal-proxy |                    |
   |            +-------------+                    |
   |               |                               |
   |               v forward                       |
   | pull         3001                             v access
   |    +----------------+     send mail      +-------------+
   +--> | thruster       |-------------> 1025 | MailCatcher |
        |  -> 3000 Rails |    "kamal"         +-------------+
        +----------------+    Network              ^ pull
===================================================|==============
                                                   |      Internet
                                            +~~~~~~~~~~~~+
                                            | Docker Hub |
                                            +~~~~~~~~~~~~+
```

- Developer および User はステージング環境をテストする開発者を表します。ここからデプロイ、およびサービスの利用を行います。
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

## デプロイ先の Docker エンジン

この例では、デプロイ先サーバーでは Docker エンジンがすでに稼働している状態を前提としてます。

Kamal には Docker 自体を自動でインストールする機能もありますが、それを利用するにはデプロイ先へログインする SSH ユーザとして `root` を設定しなければならなくなり、その後も継続して root ユーザでのアセクスが必要になってしまいます。今回の例では、デプロイ先へ SSH 接続するユーザは、この例の設定としては環境変数 `DEPLOY_SSH_USER` に設定するユーザです。これは一般ユーザを想定しています。

一般ユーザが Docker コンテナを作成するには、そのユーザーがグループ `docker` に属している必要がありますので、その状況を確認してください。まだグループに属していなければ、次のようにして参加させることができます：

```sh
$ sudo usermod -aG docker <username>
```

Docker エンジンがまだインストールされていない場合は、次のようにインストールできます。なお Docker の Rootless モードは未検証ですので、インストールそのものは特権ユーザで行ってください：

```sh
# Rocky Linux 9 の場合の例
$ sudo dnf install -y dnf-plugins-core
$ sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
$ sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
$ sudo systemctl enable --now docker
```

## 永続化ボリューム

アプリケーションの Docker コンテナにマウントするボリュームとして、任意のディレクトリを環境変数 `DEPLOY_VOLUMES_STORAGE` にて設定することになりますが、そのディレクトリを作成してください。

```sh
$ mkdir $HOME/data
```

このディレクトリは最初のデプロイの前に作成しなければいけません。もし後になってしまった場合は、おそらく、デプロイ後のアプリケーションの起動に失敗するかもしれません。その場合はディレクトリにアプリケーションが書き込みできる権限があるか、パーミッションを確認してください。

## config/deploy.yml

Kamal の設定ファイルである `config/deploy.yml` にはただ一つの記述 `require_destination: true` という設定だけがあります。これはデプロイ先に応じた別の設定ファイルの存在を暗示しており、実行時にはそのデプロイ先を指定する必要があることを設定しています。

デプロイ先がステージング環境用のものは、サンプルとしてファイル `config/deploy.staging.yml.sample` が用意されていますので、これを `config/deploy.staging.yml` という名のファイルに複製し、これをカスタムしてください。

いま説明している例の構成においては、何も変更する箇所はありません。変更するべきすべての値は環境変数から読み取るようになっています。設定する必要がある環境変数については後述します。

## .kamal/secrets

ファイル `config/deploy.staging.yml` の記述の中で秘匿情報にあたる部分は、別管理のファイル `.kamal/secrets` があります。そしてこれもまた、 Kamal のデプロイ先に応じた別のファイルがあります。この例ではステージング環境であるので、ここでは `.kamal/secrets.staging` がその扱うべき対象のファイルとなります。

前項で述べた設定ファイル `config/deploy.staging.yml` を変更していないのであれば、 `.kamal/secrets.staging` についても修正箇所はありません。変更するべきすべての値は、環境変数から読み取るようになっています。

## コンテナ・レジストリ

Kamal のデプロイでは、ビルドされたイメージは、コンテナー・レジストリへ push されることになります。

Kamal のバージョン 2.8 からは、ホストマシン上の（ローカルの） Docker コンテナを指定することができるようになり、外部のコンテナ・レジストリ・サービスは必ずしも必要ではなくなりました。

外部サービスを利用する場合は、そのアカウントが必要です。ローカルのコンテナ・レジストリを利用する場合は、 Kamal がデプロイ時に設置しますので、別途必要なものはありません。

## SSL (TLS) 証明書と hosts ファイル

SSL(TLS) のサーバー証明書については、 Kamal では Let's Encrypt （外部サービス）を利用した証明書の作成（更新）を自動で行う機能がありますが、この例では LAN 内に構築するステージング環境という都合から、 mkcert を利用した自前のルート認証局をあらかじめ作成し、そのルート証明書を User の環境およびデプロイ先の環境にインストールしておくことになります。

またその際、 Common Name となるホスト名が解決できなければいけないため、 `/etc/hosts` ファイルにホスト名を登録しておきます（もし LAN 内のアドレスを解決できる DNS が利用できるのであれば、それで十分です）

## 環境変数の設定

アプリケーション設定や、デプロイ設定のために必要な、環境変数を設定します。

アプリケーション設定のための環境変数、およびデプロイ設定のための環境変数については [/docs/ENVIRONMENT_VARIABLES.md](/docs/ENVIRONMENT_VARIABLES.md) を参照してください。

## デプロイの実行

シェルに環境変数をセットしたのち、デプロイします。最初のデプロイ時にはアクセサリを先にデプロイします：

```
$ bundle exec kamal accessory boot mailcatcher --destination=staging
```

次にアプリ本体をデプロイします：

```
$ bundle exec kamal deploy --destination=staging
```

dotenv を使って環境変数を設定しながら実行する場合は、ファイル `.env.staging` を指定しながら実行します：

```
$ dotenv -f .env.staging bundle exec kamal accessory boot mailcatcher --destination=staging
$ dotenv -f .env.staging bundle exec kamal deploy --destination=staging
```

ディレクトリが Git 管理下にない場合は、 `--version ...` オプションを用いてバージョンを指定してください：

```
$ dotenv -f .env.staging bundle exec kamal deploy --destination=staging --version=12345
```
