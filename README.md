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

- Dart SDK 3.8.0 以上
- Jaspr CLI（`dart pub global activate jaspr_cli`）

## セットアップ

```sh
dart pub get
```

## 静的解析

```sh
dart analyze
```
