# この Dockerfile は、Docker ボリューム (storage) に保存された SQLite データベース
# ファイルにコンテナ内からアクセス・操作するためのイメージを作成します。
# 例: `docker compose run --rm sqlite sqlite3 /rails/storage/development.sqlite3`
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*
WORKDIR /data
ENTRYPOINT ["sqlite3"]
