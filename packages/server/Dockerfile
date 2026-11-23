FROM dart:3.14.1 AS build

WORKDIR /app

# pub workspaces の解決に必要な全パッケージの pubspec を先にコピーし依存キャッシュを効かせる
COPY pubspec.yaml pubspec.lock ./
COPY packages/shared/pubspec.yaml packages/shared/pubspec.yaml
COPY packages/server/pubspec.yaml packages/server/pubspec.yaml
COPY packages/web/pubspec.yaml packages/web/pubspec.yaml
RUN dart pub get --enforce-lockfile

COPY packages/shared packages/shared
COPY packages/server packages/server

WORKDIR /app/packages/server
# sqlite3 パッケージが build hooks を使うため dart compile exe ではなく dart build cli でネイティブ資産ごとバンドルする
RUN dart build cli -t bin/server.dart -o /app/build

FROM dart:3.14.1

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/build/bundle/ /app/
RUN mkdir -p /data

ENV HOST=0.0.0.0
ENV PORT=8080
ENV DATABASE_PATH=/data/rss_reader.db

EXPOSE 8080

# exec 形式で起動し、docker compose down 時の SIGTERM を直接 Dart プロセスへ届ける
ENTRYPOINT ["/app/bin/server"]
