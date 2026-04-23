[English version is here](SETUP_VNC.md)

# VNC（TigerVNC）をインストールして GUI で Chromium を操作する

このドキュメントは、コンテナ内に VNC サーバ（TigerVNC / Xvnc）をインストールし、ホスト・マシンから Chromium などを GUI で操作できるようにするための手順です。

VNC は任意です。ブラウザをヘッドレス・モードで使うだけであったり、その他 GUI が不要である場合は、本手順を実施する必要はありません。ブラウザ導入手順は [docs/SETUP_BROWSER.ja.md](/docs/SETUP_BROWSER.ja.md) にあります。

## 背景

RSpec の system spec には Chrome または Chromium ブラウザが必要ですが、GUI が利用できなくてもヘッドレス・モードで実行できます。

しかし、失敗時の調査や手動での動作確認では、ブラウザ画面を直接見たいことがあります。そこで軽量な TigerVNC (Xvnc) と Fluxbox を用い、必要なときだけ GUI セッションを開けるようにしています。

## 前提

- 開発環境はトップの `Dockerfile` と `compose.yml` を使用
- コンテナは起動済み

```bash
$ docker compose up
```

## ポート公開

VNC は TCP ポート 5901 を使用します。セキュリティのため、ホストのループバック・アドレスのみにこのポートを公開することを推奨します。また VNC は平文通信をするため、より安全な接続が必要になる場合は、別途 SSH トンネルを使うか、VNC over TLS を検討してください。

リポジトリにコミットしない個人用の `compose.override.yml` をトップ・ディレクトリに用意してください。Docker Compose でコンテナを起動すると、自動で読み込まれます。

`compose.override.yml` の例:

```yaml
services:
  web:
    ports:
      - "127.0.0.1:5901:5901"
```

## 1. VNC 関連パッケージ一式をインストール

ルートユーザでインストールします。バッチスクリプトが用意されているので、それを実行します。

```bash
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/install-vnc-tigervnc.sh"
```

このスクリプトは次を行います。

- `tigervnc-standalone-server`、`tigervnc-common`、`tigervnc-tools`、`fluxbox`、`autocutsel` のインストール
- `rails` ユーザの作成（なければ）
- `/tmp/.X11-unix` の準備

## 2. VNC サーバ起動

任意のパスワードを設定しながら、用意されているバッチ・スクリプトを用いて起動させます。

```bash
$ docker compose exec web bash -lc \
  "VNC_PASSWORD='set-your-vnc-pass' VNC_DISPLAY_NUMBER=1 VNC_GEOMETRY='1280x800' /bin/bash /rails/scripts/vnc-start.sh"
```

停止および状態確認のためのバッチ・スクリプトもあります。

```bash
$ docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-stop.sh"
$ docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-status.sh"
```

`vnc-start.sh` は `scripts/xstartup.template` を `~/.vnc/xstartup` にコピーしてから起動します。必要に応じてこのテンプレートを編集してカスタマイズできます。

## 3. ホストから接続

- 接続先: `127.0.0.1:5901`
- パスワード: VNC サーバ起動時に指定したパスワード

VNC クライアントには TigerVNC が使えますが、安定性には環境差があります。これは筆者の macOS (Monterey) が古いせいかもしれませんが、利用できた実績があるバージョンは `TigerVNC Viewer 1.12.0.app` です。ただしこのバージョンでも `Option...` メニューを開こうとするとクラッシュすることがありました。一方、`TigerVNC Viewer 1.15.0.app` は `Option...` を開けるものの、接続時にクラッシュしました。そのため筆者は 1.15.0 でオプションを設定し、別途 1.12.0 で接続していました。

macOS 標準の「画面共有」アプリも利用できますが、クリップボードは使えません。ただし接続は安定しているため、その制約が許容できるのであれば実用的な選択肢です。

## 4. RSpec + Cuprite で画面を見ながら実行

ブラウザの画面を見ながら system spec を動かしたい場合は、環境変数 `HEADLESS=0` を指定し、かつ `DISPLAY=:1` も指定してください。なお `HEADLESS` 環境変数の扱いは `spec/support/capybara.rb` に定義されており、その他の cuprite ドライバー・オプションもそこにあります。

```bash
$ docker compose exec web bash -lc "HEADLESS=0 DISPLAY=:1 bundle exec rspec spec/system"
```

## トラブルシュート

- 接続できない
  `compose.override.yml` のポート公開が有効か `docker compose ps` で確認してください。
  コンテナ側で `vncserver -list` や `pgrep -a Xvnc` を実行し、プロセスが生きているか確認してください。

- 画面が真っ黒
  `fluxbox` と `chromium` のインストール状態を確認し、必要に応じて `/rails/scripts/vnc-start.sh` を手動実行してください。

- パスワード関連
  `~/.vnc/passwd` の権限が `600` になっていること、かつファイルが空でないことを確認してください。
  VNC を停止の上、インストールスクリプトを root で再実行して `vncpasswd` を確保し、VNC を再起動してください。