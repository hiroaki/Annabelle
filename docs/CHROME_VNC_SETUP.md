# Chrome/Chromium + VNC in Dev Container

この手順書は、Docker Compose で起動した開発用コンテナの中に GUI で操作できる Chromium ブラウザと VNC 環境（Xvfb + x11vnc）を追加でセットアップし、ホストから VNC クライアントで閲覧・操作できるようにするためのものです。イメージのビルド段階ではインストールしません。開発者が必要なタイミングで、コンテナ起動後に実行してください。

In short: install Chromium and a minimal VNC stack (Xvfb + x11vnc) inside the already-running dev container, start a lightweight window manager session (Fluxbox) on DISPLAY :1 (exposed via 5901), and connect from your host’s VNC viewer.

---

## Prerequisites / 前提

- macOS (Apple Silicon 含む)
- Docker Desktop インストール済み
- 本リポジトリの開発環境は top-level の `Dockerfile` と `compose.yml` を使用
- コンテナは通常どおり起動しておく（Rails サーバは自動起動しません）

```
$ docker compose up --build
```

別ターミナルから作業します。

```
$ docker compose exec web bash
```

以降の手順では、必要に応じて `--user root`（root 権限で実行）と、`--user rails`（通常ユーザ）を切り替えます。

---

## Optional: Local override for VNC port / 追加のポート公開

VNC は 5901/tcp を使用します。セキュリティのため、ホストの loopback のみに公開することを推奨します。リポジトリにコミットしない個人用の `compose.override.yml` をカレントに用意してください（Docker Compose は自動で読み込みます）。

compose.override.yml（例）：

```yaml
services:
  web:
    ports:
      - "127.0.0.1:5901:5901"  # VNC :1 (=5901) をホストの localhost のみに公開
```

作成後、`docker compose up -d` で反映されます。

---

## 1) Install browser and VNC inside the container / コンテナ内にブラウザと VNC をインストール

開発コンテナは既定でユーザ `rails` で動作しています。パッケージのインストールは root 権限が必要です。用意済みのスクリプトを root で実行します：

```
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/install_chromium_vnc.sh"
```

このスクリプトは以下を実施します：
- Chromium（Google Chrome 互換）本体と依存パッケージのインストール
- Xvfb（仮想 X）+ x11vnc（VNC ブリッジ）、Fluxbox（軽量 WM）、フォント類（Noto CJK/Emoji, Liberation）
- 互換性のため `/usr/bin/google-chrome` と `/usr/bin/chromium-browser` を `chromium` にシンボリックリンク

Apple Silicon/Intel どちらのホストでも、Debian ベースのコンテナ内では `chromium` が利用されます。

---

## 2) Start VNC server / VNC サーバ起動

VNC の起動は通常ユーザ（`rails`）で行います。初回はパスワードの設定を行い、Xvfb/Fluxbox/Chromium を起動し、x11vnc を DISPLAY に接続します（手動実行）。

```
$ docker compose exec web bash -lc \
  "VNC_PASSWORD='set-your-vnc-pass' /bin/bash /rails/scripts/vnc-start.sh"
```

デフォルトの表示は `:1`、解像度は `1280x800` です。変更したい場合：

```
$ docker compose exec web bash -lc \
  "VNC_PASSWORD='set-your-vnc-pass' VNC_DISPLAY=':1' VNC_GEOMETRY='1440x900' /bin/bash /rails/scripts/vnc-start.sh"
```

停止は次のコマンドで行えます：

```
$ docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-stop.sh"
```

---

## 3) Connect from host / ホストから接続

1. 任意の VNC クライアント（TigerVNC Viewer, RealVNC Viewer など）をホストにインストール
2. 接続先に `127.0.0.1:5901` を指定（上記 override を設定している前提。コンテナ内の x11vnc は 0.0.0.0 で待受、ホスト側は 127.0.0.1 にのみ公開）
3. 先ほど設定した VNC パスワードでログイン

ログインすると Fluxbox の軽量デスクトップが表示され、Chromium が自動起動します。GUI でのデバッグが可能です。

セキュリティ注意：VNC は平文認証を行います。必ずホストの `127.0.0.1` のみにポートを公開してください（`compose.override.yml` の `127.0.0.1:5901:5901`）。リモート接続が必要な場合は、SSH トンネル経由を推奨します。

### Clipboard / クリップボードについて

- コンテナ側では `autocutsel` により X の PRIMARY/CLIPBOARD を同期するよう設定しています（`vnc-start.sh` が自動で起動）。
- ただし、macOS 純正の「画面共有.app（Screen Sharing）」は接続先の VNC サーバにより、クリップボード連携トグルが無効化され表示されることがあります（グレーアウト）。この場合は連携されません。
- クリップボード連携が必要な場合は、TigerVNC Viewer または RealVNC Viewer など、クリップボード同期をサポートするクライアントの使用をおすすめします。
- 動作確認：コンテナ内で `pgrep -a autocutsel` を実行し、`PRIMARY` と `CLIPBOARD` の2つが起動していることを確認できます。

---

## 4) Using with RSpec + Cuprite / RSpec + Cuprite との併用メモ

- ヘッドレス実行のままであれば追加設定は不要です（VNC は無関係）。
- GUI を映しながら System Spec を動かしたい場合、`HEADLESS=0` を指定し、`DISPLAY=:1` を使うようにしてください（本プロジェクトでは `:cuprite_custom` ドライバが `HEADLESS` を解釈します）。

実行例：

```
$ docker compose exec web bash -lc "export DISPLAY=:1 HEADLESS=0; bundle exec rspec spec/system"
```

---

## Troubleshooting / トラブルシュート

- VNC に接続できない
  - `compose.override.yml` のポート公開が有効か確認（`docker compose ps`）。
  - コンテナ側で `pgrep -a x11vnc` と `pgrep -a Xvfb` を実行し、プロセスが生きているか確認。
  - ホスト側の公開は `compose.override.yml` で `127.0.0.1` のみにバインドしてください（セキュリティのため）。

- Chromium が見つからない / 起動しない
  - `docker compose exec --user root web bash -lc "apt-get update"` を再実行後、インストールスクリプトをやり直す。
  - 依存パッケージ（`libnss3` など）は `chromium` で自動導入されます。

- 画面が真っ黒のまま
  - `fluxbox` と `chromium` が存在するか確認。`/rails/scripts/vnc-start.sh` を手動で実行して起動します。

---

## What the scripts do / スクリプトの役割

- `scripts/install_chromium_vnc.sh`（root 用）
  - Chromium, Xvfb, x11vnc, Fluxbox, フォントなどの導入。
  - `/usr/bin/google-chrome` → `chromium` の互換シンボリックリンク作成。

- `scripts/vnc-start.sh`（rails ユーザ用）
  - 初回の VNC パスワード設定、Xvfb/Fluxbox/Chromium 起動、x11vnc 起動。

- `scripts/vnc-stop.sh`（rails ユーザ用）
  - 指定 DISPLAY の x11vnc/Xvfb を停止。

---

以上で、開発用コンテナ内に GUI 付きブラウザを用意し、VNC 経由で操作・デバッグできるようになります。
