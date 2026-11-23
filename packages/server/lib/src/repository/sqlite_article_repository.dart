import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart';

import 'article_repository.dart';
import 'repository_exception.dart';
import 'stored_article.dart';

/// マイグレーション済みの [Database] に記事を保存する。
/// ID は `AUTOINCREMENT` の値を10進の文字列にしたもの。
final class SqliteArticleRepository implements ArticleRepository {
  SqliteArticleRepository(this._db);

  final Database _db;

  @override
  Future<List<StoredArticle>> addAll(
    String feedId,
    List<Article> articles,
  ) async {
    final added = <StoredArticle>[];
    _db.execute('BEGIN');
    try {
      final insert = _db.prepare(
        'INSERT OR IGNORE INTO articles '
        '(feed_id, unique_key, base_date, article_json) VALUES (?, ?, ?, ?)',
      );
      try {
        for (final a in articles) {
          final key = _uniqueKey(a);
          if (key == null) continue;

          insert.execute([
            feedId,
            key,
            _baseDate(a)?.microsecondsSinceEpoch,
            jsonEncode(a.toJson()),
          ]);
          if (_db.updatedRows != 1) continue;

          added.add(
            StoredArticle(
              id: '${_db.lastInsertRowId}',
              feedId: feedId,
              article: a,
              isRead: false,
            ),
          );
        }
      } finally {
        insert.close();
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return added;
  }

  @override
  Future<StoredArticle?> findById(String id) async {
    final rowId = _parseId(id);
    if (rowId == null) return null;

    final rows = _db.select('SELECT * FROM articles WHERE id = ?', [rowId]);
    return rows.isEmpty ? null : _toStoredArticle(rows.first);
  }

  @override
  Future<List<StoredArticle>> find({
    String? feedId,
    bool unreadOnly = false,
    int? limit,
    int offset = 0,
  }) async {
    if (limit != null && limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be at least 1');
    }
    RangeError.checkNotNegative(offset, 'offset');

    final rows = _db.select(
      'SELECT * FROM articles '
      'WHERE (?1 IS NULL OR feed_id = ?1) AND (?2 = 0 OR is_read = 0) '
      'ORDER BY base_date IS NULL, base_date DESC, id ASC '
      'LIMIT ?3 OFFSET ?4',
      [feedId, unreadOnly ? 1 : 0, limit ?? -1, offset],
    );
    return [for (final row in rows) _toStoredArticle(row)];
  }

  @override
  Future<StoredArticle> setRead(String id, {required bool isRead}) async {
    final rowId = _parseId(id);
    if (rowId != null) {
      _db.execute('UPDATE articles SET is_read = ? WHERE id = ?', [
        isRead ? 1 : 0,
        rowId,
      ]);
      if (_db.updatedRows > 0) return (await findById(id))!;
    }
    throw ArticleNotFoundException(id);
  }
}

StoredArticle _toStoredArticle(Row row) => StoredArticle(
  id: '${row['id']}',
  feedId: row['feed_id'] as String,
  article: Article.fromJson(
    jsonDecode(row['article_json'] as String) as Map<String, dynamic>,
  ),
  isRead: row['is_read'] == 1,
);

/// フィード内で記事を一意に識別するキー。RSS は guid、なければ link、Atom は id。
/// 空文字の guid / link は「ない」として扱う。
/// キーが作れない記事は null。
String? _uniqueKey(Article article) => switch (article) {
  RssArticle(:final guid, :final link) => _nonEmpty(guid) ?? _nonEmpty(link),
  AtomArticle(:final id) => id,
};

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

/// 並び順の基準日時。
DateTime? _baseDate(Article article) => switch (article) {
  RssArticle(:final pubDate) => pubDate,
  AtomArticle(:final published, :final updated) => published ?? updated,
};

/// 採番した10進の文字列だけを rowid に戻す。`01` / `+1` / `0x1` / ` 1` などは null。
int? _parseId(String id) {
  final rowId = int.tryParse(id);
  return rowId != null && '$rowId' == id ? rowId : null;
}
