import 'dart:io';

import 'package:server/src/repository/sqlite_schema.dart';
import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

final rssWithEnclosure = RssArticle(
  title: 'ポッドキャスト',
  guid: 'ep-1',
  pubDate: DateTime.utc(2026, 11, 5),
  enclosure: RssEnclosure(
    url: 'https://tminasen.dev/ep1.mp3',
    length: 1024,
    type: 'audio/mpeg',
  ),
);

/// マイグレーション済みのインメモリ DB。テスト終了時に閉じる。
Database openMigratedInMemory() {
  final db = sqlite3.openInMemory();
  addTearDown(db.close);
  migrateSqliteSchema(db);
  return db;
}

/// 一時ディレクトリの下の DB ファイルのパス。テスト終了時にディレクトリごと消す。
String tempDbPath() {
  final dir = Directory.systemTemp.createTempSync('mth65_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return '${dir.path}/rss.db';
}

/// [path] の DB を開いてマイグレーションを当てる。前に開いた DB は先に閉じておくこと。
Database reopen(String path) {
  final db = sqlite3.open(path);
  addTearDown(db.close);
  migrateSqliteSchema(db);
  return db;
}
