Note: This document and related files (files in the docker directory) are scheduled for deletion.
For Docker environment setup, please use the Dockerfile located in the top-level directory.

注意：この文書および関係ファイル（ /docker ディレクトリ内のファイル）は削除予定です。 Docker 環境の構築についてはトップ・ディレクトリにある Dockerfile を使用してください。

-----

# Dockerfile.vips

## Purpose / 作成意図

`Dockerfile.vips` is provided for testing the Annabelle application in an environment where the `libvips` image processing library is available. This allows you to verify and use Active Storage with the `vips` backend, which is often faster and more efficient than ImageMagick for certain image operations.

`Dockerfile.vips` は、Annabelle アプリケーションが `libvips` 画像処理ライブラリのある環境で**動作テストを行うため**に用意されています。これにより、Active Storage の画像処理バックエンドとして `vips` を使った動作確認や利用が可能になります。`vips` は特定の画像処理で ImageMagick より高速かつ効率的な場合があります。

## How to use / 使い方

Run these commands from the project’s top directory.

これらのコマンドをプロジェクトのトップディレクトリで実行します。

(1)  Build the Docker image:  

(1) Docker イメージをビルドします:  

```shell
$ docker build -f docker/Dockerfile.vips -t annabelle-vips .
```

(2) Run the container starts Rails:

(2) コンテナを起動することで Rails が起動します:

```shell
$ docker run --rm -it -p 13000:3000 \
  -e ANNABELLE_VARIANT_PROCESSOR=vips annabelle-vips
```

This will make the application available at [http://localhost:13000](http://localhost:13000).

この操作でアプリケーションは [http://localhost:13000](http://localhost:13000) で利用可能になります。

Try uploading a video file to make sure it appears in the message and its preview displays correctly.

手動で動画ファイルをアップロードし、それがメッセージ内に表示されプレビューできることを確認してください。

## Issue / 課題

In the current version, the Chrome browser is installed in the same image as the application, but we plan to prepare a separate container image and use it with Docker Compose.

現在のバージョンでは Chrome ブラウザをアプリケーションと同じイメージにインストールしてますが、別のコンテナ・イメージを用意し、 Docker Compose で使うようにする予定です。
