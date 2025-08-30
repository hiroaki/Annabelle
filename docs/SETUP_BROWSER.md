# Chromium ブラウザのインストールとセットアップ

このドキュメントは、RSpec のシステム・テストで使用する Chromium ブラウザを、開発用コンテナにインストールする手順です。

## 背景

このプロジェクトでは Capybara のドライバーとして cuprite を採用しています。cuprite は Chrome/Chromium を CDP (Chrome DevTools Protocol) 経由でリモートのホストからも操作ができることから Docker 環境ではアプリケーションとは別のプロセス（コンテナ）で実行する構成が望まれますが、Apple Silicon (ARM64) では動作が安定しません。

このような事情から、（そして何より大前提としてプロジェクトオーナーの開発環境が M1 Mac 上であるため、）その環境で現時点で比較的安定して動作する方法として、テスト対象アプリケーションのコンテナ内に Chrome 互換の Chromium を直接インストールする構成を採用しています。

ほかのアーキテクチャ上で開発を行う場合はこのドキュメントに従う必要はありません。任意に Chrome をインストールし、自ら環境を構築してください。（そのためブラウザはイメージには含めずに、後から任意に追加する形を採用しています）

## 前提

- macOS（Apple Silicon 含む）
- 開発環境はトップの `Dockerfile` と `compose.yml` を使用
- コンテナは起動済み

```bash
$ docker compose up
```

## 手順

ルートユーザでインストールします。バッチスクリプトが用意されていますのでそれを実行します：

```bash
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/browser-install-chromium.sh"
```

このスクリプトは次を行います：
- `chromium` 本体と基本フォント（Liberation/Noto）をインストール
- 互換のため `/usr/bin/google-chrome` と `/usr/bin/chromium-browser` を `chromium` へシンボリックリンク

## RSpec での利用


RSpec は、デフォルトではブラウザはヘッドレス・モードで動作するようになっています。言い換えると、ヘッドレス・モードをオフにした実行はできません。ブラウザの画面を表示したい場合は VNC を導入してください（`docs/SETUP_VNC.md` を参照）。

```bash
$ docker compose exec web bash -lc "bundle exec rspec spec/system"
```

## トラブルシュート

- Chromium が見つからない／起動しない
  - `apt` の更新後に再実行：
    ```bash
    docker compose exec --user root web bash -lc "apt-get update -qq && /bin/bash /rails/scripts/browser-install-chromium.sh"
    ```
