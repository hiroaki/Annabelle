# Dockerfile.vips

## Purpose / 作成意図

`Dockerfile.vips` is provided for testing the Annabelle application in an environment where the `libvips` image processing library is available. This allows you to verify and use Active Storage with the `vips` backend, which is often faster and more efficient than ImageMagick for certain image operations.

`Dockerfile.vips` は、Annabelle アプリケーションが `libvips` 画像処理ライブラリのある環境で**動作テストを行うため**に用意されています。これにより、Active Storage の画像処理バックエンドとして `vips` を使った動作確認や利用が可能になります。`vips` は特定の画像処理で ImageMagick より高速かつ効率的な場合があります。

---

## How to use / 使い方

Run these commands from the project’s top directory.

これらのコマンドをプロジェクトのトップディレクトリで実行します。

(1)  Build the Docker image:  

(1) Docker イメージをビルドします:  

```
$ docker build -f docker/Dockerfile.vips -t annabelle-vips .
```

(2) Run the container and start Rails with the vips backend:

(2) コンテナを起動し、vips バックエンドで Rails を起動します:

```
$ docker run --rm -it -p 13000:3000 \
  -e ANNABELLE_VARIANT_PROCESSOR=vips annabelle-vips
```

This will make the application available at [http://localhost:13000](http://localhost:13000).

この操作でアプリケーションは [http://localhost:13000](http://localhost:13000) で利用可能になります。

You can manually upload a video file to confirm that it appears in the message and its preview is displayed correctly.

手動で動画ファイルをアップロードし、それがメッセージ内に表示されプレビューできることを確認してください。
