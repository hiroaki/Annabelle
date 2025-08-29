# 開発環境コンテナに Chromium + VNC をセットアップする

この手順書は、Docker Compose で起動した開発用コンテナの中に GUI で操作できる Chromium ブラウザと VNC 環境（TigerVNC の Xvnc）を追加でセットアップし、ホストから VNC クライアントで閲覧・操作できるようにするためのものです。イメージのビルド段階ではインストールしません。開発者が必要なタイミングで、コンテナ起動後に実行してください。

## 背景

このプロジェクトでは、システム・テストを担う Capybara のドライバーに cuprite を使用しています。cuprite は Chrome（または Chromium）ブラウザを CDP (Chrome DevTools Protocol) 経由で制御するドライバで、Docker 構成においては操作対象のブラウザを、アプリケーションとは別のプロセス（コンテナ）で実行する構成が望まれます。

しかしながら Apple M1（ARM64）チップを搭載した Mac 上の Docker 環境では、動作が安定しません。これには次のような事情が影響していると考えられます：
- Chrome/Chromium の ARM64 向け公式ビルドが提供されていない
- 非公式の多くの ARM64 Linux 向けパッケージは cuprite が依存する CDP の挙動が不安定

このような事情から、そして何より大前提としてプロジェクトオーナーの開発環境が M1 Mac 上であるため、その環境で現時点で比較的安定して動作する方法として、テスト対象アプリケーションのコンテナ内に Chrome 互換の Chromium を直接インストールする構成を採用しています。

本構成は Apple M1 環境特有の制約を回避するためのワークアラウンドです。同様の環境で開発する場合は、このドキュメントで案内する手順に従って、アプリケーション・コンテナ内にブラウザをセットアップしてください。

もしほかのアーキテクチャ上で開発を行う場合、今述べたようなブラウザの問題がないのであれば、このドキュメントに従う必要はありません。任意に Chrome をインストールし、その他参考にできそうなところは参考にし、自ら環境を構築してください。（そのためブラウザはイメージには含めずに、後から任意に追加する形を採用しています）

将来的にプロジェクトオーナーがマシンを買い替えた場合には、構成を改めて検討します。

## 前提

- macOS (Apple Silicon 含む)
- 開発環境はトップ・ディレクトリの `Dockerfile` と `compose.yml` を使用
- コンテナは通常どおり起動しておく

```
$ docker compose up --build
```

## 追加のポート公開

VNC はポート 5901/tcp を使用します。セキュリティのため、ホストのループバック・アドレスのみにこのポートを公開することを推奨します。また VNC は平文通信をするため、より安全な接続が必要になる場合は SSH トンネルを使う/または VNC over TLS を検討してください。

リポジトリにコミットしない個人用の `compose.override.yml` をトップ・ディレクトリに用意してください。compose でコンテナを起動すると、自動で読み込まれます。

compose.override.yml（例）：

```yaml
services:
  web:
    ports:
      - "127.0.0.1:5901:5901"  # VNC :1 (=5901) をホストの localhost のみに公開
```

## 構築手順

### 1) コンテナ内にブラウザと TigerVNC をインストール

開発コンテナは既定でユーザ `rails` で動作しています。パッケージのインストールは root 権限が必要です。用意済みのスクリプトを root で実行します：

```
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/install_chromium_vnc.sh"
```

（リポジトリの `scripts` ディレクトリは、コンテナ内では `/rails/scripts` になります。）

このスクリプトは以下を実施します：
- Debian/Ubuntu のパッケージとして提供される `chromium` 本体とその依存パッケージをインストールします。
- TigerVNC 関連パッケージ（`tigervnc-standalone-server`, `tigervnc-common`）に加え、`x11vnc`（`vncpasswd`の補助ツールのため）、`fluxbox`（軽量なウィンドウマネージャ）、`autocutsel`（クリップボード同期）、およびフォント類（`fonts-liberation`, `fonts-noto-cjk`, `fonts-noto-color-emoji`）をインストールします。
- 互換性のため、`/usr/bin/google-chrome` と `/usr/bin/chromium-browser` を `/usr/bin/chromium` へシンボリックリンクします。
- 実行時に `rails` ユーザが存在しない場合は作成し、`/tmp/.X11-unix` の作成・パーミッション調整を行います。また、`/rails/scripts/install_vncpasswd.sh` （x11vnc の -storepasswd を使うラッパーの作成スクリプト）があれば実行して `vncpasswd` 相当の準備を試みます。
- APT キャッシュのクリーンアップ（`apt-get clean` と `/var/lib/apt/lists` の削除）を行い、インストール後の不要なファイルを削除します。

Apple Silicon/Intel どちらのホストでも、Debian ベースのコンテナ内では `chromium` が利用されます。

このスクリプトは基本的に再実行して問題ありませんが、既存の `~/.vnc` 設定やパスワードは場合によっては上書きされます。

### 2) VNC サーバ起動

VNC の起動は通常ユーザ（`rails`）で行います。初回はパスワードの設定を行い、`vncserver`（Xvnc）が自身で X セッションを作成し、`~/.vnc/xstartup` を実行して fluxbox と chromium を起動します。

基本的な起動例（Rails ユーザで実行）:

```
# VNC_PASSWORD を指定して vncserver(:1) を作成する
$ docker compose exec web bash -lc \
  "VNC_PASSWORD='set-your-vnc-pass' VNC_DISPLAY_NUMBER=1 VNC_GEOMETRY='1280x800' /bin/bash /rails/scripts/vnc-start.sh"
```

停止は次のコマンドで行えます：

```
$ docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-stop.sh"
```

注意事項（xstartup の管理）:

- `vnc-start.sh` はリポジトリ内の `scripts/xstartup.template` を `~/.vnc/xstartup` にコピーして起動します。テンプレートが存在しない場合、起動は失敗します。
- テンプレートを編集すれば起動時のデスクトップ構成をカスタマイズできます。

ログの参照／デバッグ:

- `vnc-start.sh` はサーバをバックグラウンド起動して終了します。ログを追いたい場合は別端末で `docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-status.sh"` を実行するか、ログファイルを `ls -l /home/rails/.vnc` で確認のうえで直接参照してください。

### 3) ホストから接続

ホストから VNC のクライアントを使って接続します。

1. 接続先に `127.0.0.1:5901` を指定（`compose.override.yml` で `127.0.0.1:5901:5901` を公開している前提）
2. 先ほど設定した VNC パスワードでログイン

ログインすると Fluxbox の軽量デスクトップが表示されます。

VNC のクライアントソフトには TigerVNC を推奨します。理由はクリップボードが働くことです。クリップボードを使用しないのであれば "画面共有" アプリでもコンテナ内の画面をホスト上に出すことはできますので、試してみてください。

#### クリップボードについて

- "画面共有" アプリ（ Screen Sharing.app ）も使えますが、クリップボードが機能しません。
- TigerVNC クライアントを利用すると、サーバ／クライアント双方向クリップボードが使えます。

コンテナ側では `autocutsel` により X の PRIMARY/CLIPBOARD を同期するよう `~/.vnc/xstartup` で起動しています。これにより X 側でコピーしたテキストが VNC クリップボード側へ反映されます。

コンテナ内で `pgrep -a autocutsel` を実行すると autocutsel が動作しているのが確認できます。ホスト側でコピー → コンテナ上の Chromium に貼り付け、逆方向も試してください。

### 4) RSpec + Cuprite との併用メモ

- システム・テスト (RSpec) の実行を、ヘッドレス・ブラウザのまま実行するのであれば VNC は関係ありません。
- ブラウザの画面を見ながらシステム・テストを動かしたい場合、環境変数 `HEADLESS=0` を指定し、かつ `DISPLAY=:1` も指定してください。（なお `HEADLESS` 環境変数を使うことについては `spec/support/capybara.rb` にて定義しています。その他 cuprite のドライバー・オプションがそこで定義されています。）

  実行例：

  ```
  $ docker compose exec web bash -lc "DISPLAY=:1 HEADLESS=0 bundle exec rspec spec/system"
  ```

## トラブルシュート

- VNC に接続できない
  - `compose.override.yml` のポート公開が有効か確認（`docker compose ps`）。
  - コンテナ側で `vncserver -list` や `pgrep -a Xvnc` を実行し、プロセスが生きているか確認。
  - ホスト側の公開は `compose.override.yml` で `127.0.0.1` のみにバインドしてください（セキュリティのため）。

- Chromium が見つからない / 起動しない
  - `docker compose exec --user root web bash -lc "apt-get update"` を再実行後、インストールスクリプトをやり直す。

- 画面が真っ黒のまま
  - `fluxbox` と `chromium` が存在するか確認。`/rails/scripts/vnc-start.sh` を手動で実行して起動します。

- passwd ファイルが 0 バイトになっている / 認証エラーが出る場合

  簡潔な対処: VNC を停止の上、インストールスクリプトを root で再実行して `vncpasswd` を確保し、 VNC を再起動してください。通常これだけで問題は解決します。

  ```
  $ docker compose exec --user root web bash -lc \
    "/bin/bash /rails/scripts/install_chromium_vnc.sh"
  $ docker compose exec web bash -lc \
    "VNC_PASSWORD='your-secret-password' VNC_DISPLAY_NUMBER=1 /bin/bash /rails/scripts/vnc-start.sh"
  ```

## スクリプトの役割

- `scripts/install_chromium_vnc.sh`（root 用）
  - コンテナ内で `chromium` 本体、`tigervnc-standalone-server`/`tigervnc-common`、`x11vnc`、`fluxbox`、`autocutsel`、およびフォント類を apt でインストールします。
  - `/usr/bin/google-chrome` と `/usr/bin/chromium-browser` を `/usr/bin/chromium` にシンボリックリンク（存在する場合）。
  - `rails` ユーザの作成や `/tmp/.X11-unix` のパーミッション調整、`install_vncpasswd.sh` の自動実行による `vncpasswd` の確保、APT キャッシュのクリーンアップを行います。

- `scripts/install_vncpasswd.sh`（root 用）
  - システムに `vncpasswd` がなければ、`x11vnc` の `-storepasswd` を利用する小さなラッパーを `/usr/local/bin/vncpasswd` に作成します（存在する場合は何もしません）。

- `scripts/vnc-start.sh`（rails ユーザ用）
  - 環境変数で指定した `VNC_PASSWORD`/`VNC_DISPLAY_NUMBER`/`VNC_GEOMETRY` を使い、`~/.vnc/passwd` を初回作成（必要な場合）した上で `vncserver`（Xvnc）を起動します。
  - リポジトリの `scripts/xstartup.template` を `~/.vnc/xstartup` にコピーして実行権を付与し、起動時にそれを使って Fluxbox・autocutsel・Chromium を立ち上げます。

- `scripts/vnc-status.sh`（任意）
  - 現在の vncserver セッション一覧、関連プロセス（Xvnc/Xtigervnc/fluxbox 等）、および直近の `~/.vnc` ログを簡易的に表示します。デバッグ用途に便利です。

- `scripts/vnc-stop.sh`（rails ユーザ用）
  - 指定した DISPLAY（デフォルト :1）で動作する vncserver を `vncserver -kill :N` で停止します。

- `scripts/xstartup.template`
  - `vnc-start.sh` によってユーザの `~/.vnc/xstartup` にコピーされるテンプレートです。`autocutsel` によるクリップボード同期、`chromium` の起動、軽量 WM（`fluxbox` または `openbox`）の起動を行い、セッションを継続させる簡素なループで終わります。変更すればデスクトップ起動時の挙動をカスタマイズできます。
