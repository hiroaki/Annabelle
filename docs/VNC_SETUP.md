# VNC（TigerVNC）をインストールして GUI で Chromium を操作する

このドキュメントは、コンテナ内に VNC サーバ（TigerVNC/Xvnc）をインストールし、ホスト・マシンから Chromium などを  GUI で操作できるようにするための手順です。

VNC は任意（オプション）です。ブラウザをヘッドレス・モードで使うだけであったり、その他 GUI が不要である場合は、本手順を実施する必要はありません。

## 背景

RSpec のシステム・テスト（system spec）には Chrome ブラウザが必要ですが、 GUI が利用できなくてもヘッドレス・モードで実行できます。

しかしながら、失敗時の調査や手動での動作確認ではブラウザ画面を直接見たいことがあります。そこで軽量な TigerVNC（Xvnc）と Fluxbox を用い、必要なときだけ GUI セッションを開けるようにしています。

## 前提

- 開発環境はトップの `Dockerfile` と `compose.yml` を使用
- コンテナは起動済み

```bash
$ docker compose up
```

## ポート公開

VNC はポート 5901/tcp を使用します。セキュリティのため、ホストのループバック・アドレスのみにこのポートを公開することを推奨します。また VNC は平文通信をするため、より安全な接続が必要になる場合は別途 SSH トンネルを使う/または VNC over TLS を検討してください。

リポジトリにコミットしない個人用の `compose.override.yml` をトップ・ディレクトリに用意してください。compose でコンテナを起動すると、自動で読み込まれます。

`compose.override.yml`（例）：

```yaml
services:
  web:
    ports:
      - "127.0.0.1:5901:5901"
```

## 1) VNC 関連パッケージ一式をインストール

ルートユーザでインストールします。バッチスクリプトが用意されていますのでそれを実行します：

```bash
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/vnc-install-tigervnc.sh"
```

このスクリプトは次を行います：
- `tigervnc-standalone-server`/`tigervnc-common`、`x11vnc`、`fluxbox`、`autocutsel` のインストール
- `rails` ユーザの作成（なければ）
- `/tmp/.X11-unix` の準備
- `scripts/install_vncpasswd.sh` を使った `vncpasswd` の確保

## 2) VNC サーバ起動

任意のパスワードを設定しながら、用意されているバッチ・スクリプトを用いて起動させます：

```bash
$ docker compose exec web bash -lc \
  "VNC_PASSWORD='set-your-vnc-pass' VNC_DISPLAY_NUMBER=1 VNC_GEOMETRY='1280x800' /bin/bash /rails/scripts/vnc-start.sh"
```

停止/状態確認のためのバッチ・スクリプトがあります：

```bash
$ docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-stop.sh"
$ docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-status.sh"
```

なお `vnc-start.sh` は `scripts/xstartup.template` を `~/.vnc/xstartup` にコピーして起動します。必要に応じてこのテンプレートを編集してカスタマイズすることができます。

## 3) ホストから接続

- 接続先：`127.0.0.1:5901`
- パスワード： VNC サーバ起動時に指定したパスワード

VNC クライアントには TigerVNC が使えますが、安定性に不安があります。ただしこれは私の macOS (Monterey) が古いせいかもしれませんが、利用できた実績があるバージョンは "TigerVNC Viewer 1.12.0.app" です。しかしこのバージョンでも "Option..." メニューを開こうとするとクラッシュすることがあり、また現時点で最新の "TigerVNC Viewer 1.15.0.app" は "Option..." を開くことができますが、接続するとクラッシュします。したがって私は 1.15.0 を起動してオプションを設定し、別途 1.12.0 で接続するようにしています。

macOS 標準の "画面共有" アプリも利用できますが、クリップボードが使えません。しかしながら接続は安定しているので、クリップボードの制約が許容できるのであれば、こちらがおすすめです。

## 4) RSpec + Cuprite で画面を見ながら実行

ブラウザの画面を見ながらシステム・テストを動かしたい場合、環境変数 `HEADLESS=0` を指定し、かつ `DISPLAY=:1` も指定してください。（なお HEADLESS 環境変数を使うことについては spec/support/capybara.rb にて定義しています。その他 cuprite のドライバー・オプションがそこで定義されています。）

```bash
$ docker compose exec web bash -lc "HEADLESS=0 DISPLAY=:1 bundle exec rspec spec/system"
```

## トラブルシュート

- 接続できない
  - compose.override.yml のポート公開が有効か確認（docker compose ps）。
  - コンテナ側で vncserver -list や pgrep -a Xvnc を実行し、プロセスが生きているか確認。
- 画面が真っ黒
  - `fluxbox`/`chromium` のインストール確認、`/rails/scripts/vnc-start.sh` を手動実行。
- パスワード関連
  - `~/.vnc/passwd` の権限（600）とファイルサイズ（空でない）を確認。
  - VNC を停止の上、インストールスクリプトを root で再実行して vncpasswd を確保し、 VNC を再起動してください。
