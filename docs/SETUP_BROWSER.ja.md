[English version is here](SETUP_BROWSER.md)

# Chromium ブラウザのインストールとセットアップ

このドキュメントは、RSpec のシステム・テストで使用する Chromium ブラウザを、開発用コンテナにインストールする手順です。

## 背景

このプロジェクトでは、開発環境とデプロイ向け環境で Dockerfile を共通化しています。一方で Chromium は、system spec の実行やブラウザの目視デバッグなど、一部の開発用途でのみ必要になる補助的なツールです。そのため、デフォルトの依存には含めず、オプション扱いにしています。

ブラウザをベースイメージから外すことで、共有イメージのサイズ増加を抑え、ビルド時間を短くし、デフォルトのコンテナ環境の保守対象を増やしすぎないようにしています。このため Chromium はイメージに最初から含めず、必要な場合にだけ後から追加インストールする方針にしています。

## 前提

- 開発環境はトップの `Dockerfile` と `compose.yml` を使用
- コンテナは起動済み

```bash
$ docker compose up
```

## 手順

ルートユーザでインストールします。バッチスクリプトが用意されているので、それを実行します。

```bash
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/install-browser-chromium.sh"
```

このスクリプトは次を行います。

- `chromium` 本体と基本フォント（Liberation / Noto）をインストール
- 互換のため `/usr/bin/google-chrome` と `/usr/bin/chromium-browser` を `chromium` へシンボリックリンク

## RSpec での利用

RSpec はデフォルトでブラウザをヘッドレス・モードで動作させるようになっているため、特に気にすることはありません。

```bash
$ docker compose exec web bash -lc "bundle exec rspec spec/system"
```

環境変数 `HEADLESS=0` でヘッドレスを無効化できますが、その場合は X ディスプレイが必要になるため、VNC を使うようにセットアップしてください。詳しくは [docs/SETUP_VNC.ja.md](/docs/SETUP_VNC.ja.md) を参照してください。

## トラブルシュート

- Chromium が見つからない、または起動しない
  `apt` の更新後に再実行してください。

  ```bash
  $ docker compose exec --user root web bash -lc "apt-get update -qq && /bin/bash /rails/scripts/install-browser-chromium.sh"
  ```