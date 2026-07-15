[English version is here](SETUP_BROWSER.md)

# Chromium ブラウザのインストールとセットアップ

このドキュメントは、Docker ベースの開発環境で RSpec の system spec 用 Chromium がどのように提供されるかを説明するものです。

## 背景

このプロジェクトでは、development、CI、staging、production の各環境で Dockerfile を共通化しています。一方で Chromium は system spec の実行やブラウザの目視デバッグに必要ですが、本番向けランタイムには含めたくありません。

そこで Dockerfile では複数の最終ターゲットを用意し、Docker Compose は `runtime-dev`、CI は `runtime-test` を利用します。これらのターゲットには Chromium が含まれますが、デプロイ用の `runtime` には含まれません。

## 前提

- 開発環境はトップの `Dockerfile` と `compose.yml` を使用
- コンテナは起動済み

```bash
$ docker compose up
```

## 利用可能な状態

現在の Docker ワークフローでは、手動インストールは不要です。

- `docker compose build web` は `runtime-dev` ターゲットを build し、その中に Chromium が含まれます
- GitHub Actions は `runtime-test` ターゲットを build し、同様に Chromium を含みます
- デプロイ用の `runtime` ターゲットには意図的に Chromium を含めません

Dockerfile を変更した場合や古いイメージから更新する場合は、コンテナイメージを再 build してください。

```bash
$ docker compose build web
```

## RSpec での利用

RSpec はデフォルトでブラウザをヘッドレス・モードで動作させるようになっているため、特に気にすることはありません。

```bash
$ docker compose exec web bash -lc "bundle exec rspec spec/system"
```

環境変数 `HEADLESS=0` でヘッドレスを無効化できますが、その場合は X ディスプレイが必要になるため、VNC を使うようにセットアップしてください。詳しくは [docs/SETUP_VNC.ja.md](/docs/SETUP_VNC.ja.md) を参照してください。

## トラブルシュート

- Chromium が見つからない、または起動しない
  `runtime-dev` ターゲットを作り直してください。

  ```bash
  $ docker compose build --no-cache web
  ```