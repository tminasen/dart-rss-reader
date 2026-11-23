import 'package:sqlite3/sqlite3.dart';

/// 連番のスキーマ定義。添字 + 1 がスキーマ版。
const _migrations = <String>[
  // 版1
  '''
CREATE TABLE subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feed_url TEXT NOT NULL UNIQUE,
  feed_json TEXT,
  last_fetched_at TEXT
);
CREATE TABLE articles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feed_id TEXT NOT NULL,
  unique_key TEXT NOT NULL,
  base_date INTEGER,
  article_json TEXT NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0,
  UNIQUE(feed_id, unique_key)
);
''',
];

/// コードが知っている最新のスキーマ版。
final int sqliteSchemaVersion = _migrations.length;

/// 未適用のスキーマ定義を、スキーマ版の更新とともに1つのトランザクションで適用する。
///
/// 最新版なら何もしない。DB の版がコードより新しければ [StateError] を投げる。
void migrateSqliteSchema(Database db) {
  final current = db.userVersion;
  if (current > sqliteSchemaVersion) {
    throw StateError(
      'Database schema version $current is newer than '
      'supported version $sqliteSchemaVersion',
    );
  }
  if (current == sqliteSchemaVersion) return;

  db.execute('BEGIN');
  try {
    for (final ddl in _migrations.skip(current)) {
      db.execute(ddl);
    }
    db.userVersion = sqliteSchemaVersion;
    db.execute('COMMIT');
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}
