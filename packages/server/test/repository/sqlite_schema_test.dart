import 'package:server/src/repository/sqlite_schema.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'sqlite_fixtures.dart';

int _userVersion(Database db) =>
    db.select('PRAGMA user_version').single.values.single as int;

Set<String> _tableNames(Database db) => {
  for (final row in db.select(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  ))
    row['name'] as String,
};

void main() {
  group('migrateSqliteSchema', () {
    test('should create latest schema when database is new', () {
      // Given: 新規の DB（user_version 0）
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      // When: マイグレーションを当てる
      migrateSqliteSchema(db);

      // Then: user_version が最新版で、テーブルができている
      expect(sqliteSchemaVersion, 1);
      expect(_userVersion(db), 1);
      expect(_tableNames(db), containsAll(['subscriptions', 'articles']));
    });

    test('should keep data when migration is applied twice', () {
      // Given: マイグレーション済みで1行入っている DB
      final db = openMigratedInMemory();
      db.execute(
        "INSERT INTO subscriptions(feed_url) VALUES ('https://tminasen.dev/rss/feed.xml')",
      );

      // When: もう一度マイグレーションを当てる
      migrateSqliteSchema(db);

      // Then: 例外は出ず、版もデータも変わらない
      expect(_userVersion(db), 1);
      expect(
        db.select('SELECT count(*) AS c FROM subscriptions').single['c'],
        1,
      );
    });

    test('should throw StateError when schema is newer than code', () {
      // Given: コードより新しい版（最新版+1）の DB
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      db.execute('PRAGMA user_version = 2');

      // When / Then: 拒否される
      expect(() => migrateSqliteSchema(db), throwsStateError);

      // Then: 版は変わらず、テーブルも作られない
      expect(_userVersion(db), 2);
      expect(_tableNames(db), isNot(contains('subscriptions')));
      expect(_tableNames(db), isNot(contains('articles')));
    });
  });
}
