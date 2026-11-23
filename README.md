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

- Dart SDK 3.13.0 以上 3.15.0 未満（jaspr 0.24.0-beta.2 と build_web_compilers 4.8.12 の SDK 制約による）
- Jaspr CLI 0.24.0-beta.2（`dart pub global activate jaspr_cli 0.24.0-beta.2`）

## セットアップ

```sh
dart pub get
```

## 静的解析

```sh
dart analyze
```

## 起動方法

server（8080 番）と web（8081 番）を別々のターミナルで起動します。

```sh
# server（http://localhost:8080）
cd packages/server
dart run bin/server.dart

# web（http://localhost:8081）
cd packages/web
jaspr serve
```

- web の開発サーバーのポートは `packages/web/pubspec.yaml` の `jaspr.port` で 8081 にしています。
- server は `http://localhost:8081` からのリクエストだけを CORS で許可します。
- web が呼ぶ API の URL は、既定で `http://localhost:8080` です。変える場合は `--dart-define` で指定します。

```sh
jaspr serve --dart-define=API_BASE_URL=http://localhost:9000
```

- `jaspr serve` は標準入力が端末でないと止まります。バックグラウンドで動かすときは、標準入力を開いたままにしてください（例: `sleep 600 | script -q /dev/null jaspr serve`）。
- server は起動直後と、その後は一定間隔でフィードを巡回して記事を保存します。取得できるまでの間は、画面に「タイトル未取得」「最終取得 未取得 ・ 全0件」と表示されます。
- server は次の環境変数で設定を変えられます（空文字は未指定として扱います）。

| 環境変数 | 既定値 | 説明 |
| --- | --- | --- |
| `FEED_URL` | `https://tminasen.dev/rss/feed.xml` | 購読して巡回するフィードの URL（http / https） |
| `CRAWL_INTERVAL_MINUTES` | `30` | 巡回の間隔（正の整数・分） |
| `REPOSITORY` | `sqlite` | 保存先（`memory` / `sqlite`） |
| `DATABASE_PATH` | `data/rss_reader.db` | `REPOSITORY=sqlite` のときの DB ファイル |

```sh
FEED_URL=https://example.com/feed.xml CRAWL_INTERVAL_MINUTES=10 dart run bin/server.dart
```

- `FEED_URL` を変えても、以前の URL の購読は DB に残りますが、巡回するのは現在の `FEED_URL` だけです。

## テスト

```sh
bash tool/test_all.sh
```
