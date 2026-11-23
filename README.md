# dart-rss-reader

Dart 製の RSS リーダー（フロントエンド: Jaspr / バックエンド: Shelf）。

## 構成

Dart の [pub workspaces](https://dart.dev/tools/pub/workspaces) を使ったモノレポです。

| パッケージ | 役割 |
|---|---|
| `packages/shared` | server と web で共有するコード |
| `packages/server` | Shelf によるバックエンド |
| `packages/web` | Jaspr によるフロントエンド |

## 必要な環境

### Docker Compose で起動する場合
- Docker（Docker Compose V2）

### ローカルで直接起動・開発する場合
- Dart SDK 3.13.0 以上 3.15.0 未満（jaspr 0.24.0-beta.2 と build_web_compilers 4.8.12 の SDK 制約による）
- Jaspr CLI 0.24.0-beta.2（`dart pub global activate jaspr_cli 0.24.0-beta.2`）

## セットアップ（ローカル直接実行・テスト用）

```sh
dart pub get
```

## 起動方法

### 1. Docker Compose で起動する（推奨）

リポジトリルートで次を実行すると、`server`（ポート `8080`）と `web`（ポート `8081`）がビルド・起動します。

```sh
docker compose up --build
```

- 起動後、ブラウザで `http://localhost:8081` を開くと記事を閲覧できます。
- バックグラウンドで起動する場合は `docker compose up -d --build` を使用します。
- `server` は起動直後と、その後は一定間隔（既定 30 分）で対象フィードを巡回して SQLite に保存します。取得完了までの間は画面に「タイトル未取得」「最終取得 未取得 ・ 全0件」と表示されます。

#### 読み込み先フィードの変更（Docker Compose）

既定の読み込み先フィードは `https://tminasen.dev/rss/feed.xml` です。別のフィードを読み込む場合は `FEED_URL` 環境変数を指定して起動します。

```sh
FEED_URL=https://example.com/feed.xml docker compose up --build
```

- `API_BASE_URL`（web が参照する server の URL、既定値 `http://localhost:8080`）を変更する場合は、クライアントビルド時に埋め込まれるため `--build` を付けて再ビルドしてください（`compose.yaml` の `server` はポート `8080` 固定のため、別プロセスやリバースプロキシ経由のサーバーを参照する場合に指定します）。

```sh
API_BASE_URL=http://localhost:9000 docker compose up --build
```

#### 停止・データの永続化と初期化

- 停止するときは次のコマンドを実行します。`server` は `SIGTERM` を受けて進行中の巡回完了を待ってから SQLite を安全にクローズして終了します。

```sh
docker compose down
```

- SQLite データベースは名前付き Docker ボリューム `rss_reader_data`（コンテナ内 `/data/rss_reader.db`）に保存されるため、`docker compose down` 後に再び `docker compose up` しても購読情報と記事データは保持されます。
- 保存されたデータをすべて初期化したい場合は、`-v` オプションでボリュームごと削除します。

```sh
docker compose down -v
```

### 2. ローカルで直接起動する（Docker なし）

`dart pub get` を実行した上で、server（8080 番）と web（8081 番）を別々のターミナルで起動します。

```sh
# server（http://localhost:8080）
cd packages/server
dart run bin/server.dart

# web（http://localhost:8081）
cd packages/web
jaspr serve
```

- web の開発サーバーのポートは `packages/web/pubspec.yaml` の `jaspr.port` で 8081 にしています。
- web が呼ぶ API の URL は、既定で `http://localhost:8080` です。変える場合は `--dart-define` で指定します。

```sh
jaspr serve --dart-define=API_BASE_URL=http://localhost:9000
```

- `jaspr serve` は標準入力が端末でないと止まります。バックグラウンドで動かすときは、標準入力を開いたままにしてください（例: `sleep 600 | script -q /dev/null jaspr serve`）。

## サーバーの環境変数

`server` は次の環境変数で設定を変更できます（空文字は未指定として扱います）。

| 環境変数 | 既定値（直接起動 / Compose） | 説明 |
| --- | --- | --- |
| `FEED_URL` | `https://tminasen.dev/rss/feed.xml` | 購読して巡回するフィードの URL（http / https） |
| `CRAWL_INTERVAL_MINUTES` | `30` | 巡回の間隔（正の整数・分） |
| `REPOSITORY` | `sqlite` | 保存先（`memory` / `sqlite`） |
| `DATABASE_PATH` | `data/rss_reader.db` / `/data/rss_reader.db` | `REPOSITORY=sqlite` のときの DB ファイルパス |
| `HOST` | `127.0.0.1` / `0.0.0.0` | 待ち受けホスト（空白不可） |
| `PORT` | `8080` | 待ち受けポート番号（1〜65535） |
| `ALLOWED_ORIGINS` | `http://localhost:8081` | CORS / WebSocket で許可するオリジン（カンマ区切り、http / https、パスやクエリ不可） |

```sh
FEED_URL=https://example.com/feed.xml CRAWL_INTERVAL_MINUTES=10 dart run bin/server.dart
```

- `FEED_URL` を変えても、以前の URL の購読は DB に残りますが、巡回するのは現在の `FEED_URL` だけです。

## 静的解析・フォーマット・テスト

```sh
# 静的解析
dart analyze --fatal-infos

# フォーマット検証
dart format --output=none --set-exit-if-changed .

# 全パッケージのテスト
bash tool/test_all.sh
```
