# Chrome/Chromium + VNC in Dev Container

この手順書は、Docker Compose で起動した開発用コンテナの中に GUI で操作できる Chromium ブラウザと VNC 環境（TigerVNC の Xvnc）を追加でセットアップし、ホストから VNC クライアントで閲覧・操作できるようにするためのものです。イメージのビルド段階ではインストールしません。開発者が必要なタイミングで、コンテナ起動後に実行してください。

In short: install Chromium and a minimal VNC stack (TigerVNC Xvnc via `vncserver`) inside the already-running dev container, have `vncserver` create an X session (display :1) that runs a lightweight window manager (Fluxbox) and Chromium, and connect from your host with TigerVNC Viewer for best clipboard compatibility.

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

## 1) Install browser and TigerVNC inside the container / コンテナ内にブラウザと TigerVNC をインストール

開発コンテナは既定でユーザ `rails` で動作しています。パッケージのインストールは root 権限が必要です。用意済みのスクリプトを root で実行します：

```
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/install_chromium_vnc.sh"

(Host) Make the helper scripts executable so they can be run inside the container without additional chmod steps:

```bash
chmod +x scripts/install_chromium_vnc.sh scripts/vnc-start.sh scripts/vnc-stop.sh scripts/vnc-status.sh
```
```

このスクリプトは以下を実施します：
- Chromium（Google Chrome 互換）本体と依存パッケージのインストール
- TigerVNC の `vncserver`（Xvnc）および関連パッケージ、Fluxbox（軽量 WM）、フォント類（Noto CJK/Emoji, Liberation）
- 互換性のため `/usr/bin/google-chrome` と `/usr/bin/chromium-browser` を `chromium` にシンボリックリンク

Apple Silicon/Intel どちらのホストでも、Debian ベースのコンテナ内では `chromium` が利用されます。

---

## 2) Start VNC server (TigerVNC / Xvnc) / VNC サーバ起動

VNC の起動は通常ユーザ（`rails`）で行います。初回はパスワードの設定を行い、`vncserver`（Xvnc）が自身で X セッションを作成し、`~/.vnc/xstartup` を実行して fluxbox と chromium を起動します。

基本的な起動例（Rails ユーザで実行）:

```
# VNC_PASSWORD を指定して vncserver(:1) を作成する
docker compose exec web bash -lc \
  "VNC_PASSWORD='set-your-vnc-pass' VNC_DISPLAY_NUMBER=1 VNC_GEOMETRY='1280x800' /bin/bash /rails/scripts/vnc-start.sh"
```

停止は次のコマンドで行えます：

```
docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-stop.sh"
```

---

## 3) Connect from host / ホストから接続 (TigerVNC client 推奨)

1. TigerVNC Viewer をホストにインストールすることを強く推奨します（macOS 用のクライアント）。
2. 接続先に `127.0.0.1:5901` を指定（`compose.override.yml` で `127.0.0.1:5901:5901` を公開している前提）。
3. 先ほど設定した VNC パスワードでログイン。

ログインすると Fluxbox の軽量デスクトップが表示され、Chromium が自動起動します。TigerVNC サーバ／クライアントの組合せはテキストの双方向クリップボード同期が最も信頼できます。

セキュリティ注意：VNC は平文認証を行います。必ずホストの `127.0.0.1` のみにポートを公開してください（`compose.override.yml` の `127.0.0.1:5901:5901`）。リモート接続が必要な場合は、SSH トンネル経由を推奨します。

### Clipboard / クリップボードについて

- コンテナ側では `autocutsel` により X の PRIMARY/CLIPBOARD を同期するよう `~/.vnc/xstartup` で起動します。これにより X 側でコピーしたテキストが VNC クリップボード側へ反映されます。
- TigerVNC Viewer と TigerVNC の Xvnc を組み合わせることで、VNC ネイティブのクリップボード交換が最もスムーズに動作します。macOS の Screen Sharing.app は VNC 実装の差で期待通りに動かないことがあるため、動作確認は TigerVNC Viewer で行ってください。
- 動作確認: コンテナ内で `pgrep -a autocutsel` を実行すると autocutsel が動作しているのが確認できます。ホスト側でコピー → コンテナ上の Chromium に貼り付け、逆方向も試してください。

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
  - コンテナ側で `vncserver -list` や `pgrep -a Xvnc` を実行し、プロセスが生きているか確認。
  - ホスト側の公開は `compose.override.yml` で `127.0.0.1` のみにバインドしてください（セキュリティのため）。

- Chromium が見つからない / 起動しない
  - `docker compose exec --user root web bash -lc "apt-get update"` を再実行後、インストールスクリプトをやり直す。
  - 依存パッケージ（`libnss3` など）は `chromium` で自動導入されます。

-- 画面が真っ黒のまま
  - `fluxbox` と `chromium` が存在するか確認。`/rails/scripts/vnc-start.sh` を手動で実行して起動します。

---

## What the scripts do / スクリプトの役割

- `scripts/install_chromium_vnc.sh`（root 用）
  - Chromium, TigerVNC (Xvnc via `vncserver`), Fluxbox, フォントなどの導入。
  - `/usr/bin/google-chrome` → `chromium` の互換シンボリックリンク作成。

- `scripts/vnc-start.sh`（rails ユーザ用）
  - 初回 VNC パスワード設定（`~/.vnc/passwd` の作成）と `vncserver` による Xvnc セッションの起動。
  - `~/.vnc/xstartup` を実行して fluxbox/auto-cut/Chromium を起動。

- `scripts/vnc-stop.sh`（rails ユーザ用）
  - `vncserver -kill :N` による Xvnc セッション停止。

---

以上で、開発用コンテナ内に GUI 付きブラウザを用意し、VNC 経由で操作・デバッグできるようになります。
