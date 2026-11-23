import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart';

import 'repository_exception.dart';
import 'subscription.dart';
import 'subscription_repository.dart';

/// マイグレーション済みの [Database] に購読を保存する。
/// ID は `AUTOINCREMENT` の値を10進の文字列にしたもの。
final class SqliteSubscriptionRepository implements SubscriptionRepository {
  SqliteSubscriptionRepository(this._db);

  final Database _db;

  @override
  Future<Subscription> add(String feedUrl) async {
    _db.execute('INSERT OR IGNORE INTO subscriptions(feed_url) VALUES (?)', [
      feedUrl,
    ]);
    return (await findByUrl(feedUrl))!;
  }

  @override
  Future<Subscription?> findById(String id) async {
    final rowId = _parseId(id);
    if (rowId == null) return null;
    return _first(
      _db.select('SELECT * FROM subscriptions WHERE id = ?', [rowId]),
    );
  }

  @override
  Future<Subscription?> findByUrl(String feedUrl) async => _first(
    _db.select('SELECT * FROM subscriptions WHERE feed_url = ?', [feedUrl]),
  );

  @override
  Future<List<Subscription>> findAll() async => [
    for (final row in _db.select('SELECT * FROM subscriptions ORDER BY id'))
      _toSubscription(row),
  ];

  @override
  Future<Subscription> updateFetched(
    String id, {
    required Feed feed,
    required DateTime fetchedAt,
  }) async {
    final rowId = _parseId(id);
    if (rowId != null) {
      _db.execute(
        'UPDATE subscriptions SET feed_json = ?, last_fetched_at = ? '
        'WHERE id = ?',
        [jsonEncode(feed.toJson()), fetchedAt.toIso8601String(), rowId],
      );
      if (_db.updatedRows > 0) return (await findById(id))!;
    }
    throw SubscriptionNotFoundException(id);
  }
}

Subscription? _first(ResultSet rows) =>
    rows.isEmpty ? null : _toSubscription(rows.first);

Subscription _toSubscription(Row row) {
  final feedJson = row['feed_json'] as String?;
  final lastFetchedAt = row['last_fetched_at'] as String?;
  return Subscription(
    id: '${row['id']}',
    feedUrl: row['feed_url'] as String,
    feed: feedJson == null
        ? null
        : Feed.fromJson(jsonDecode(feedJson) as Map<String, dynamic>),
    lastFetchedAt: lastFetchedAt == null ? null : DateTime.parse(lastFetchedAt),
  );
}

/// 採番した10進の文字列だけを rowid に戻す。`01` / `+1` / `0x1` / ` 1` などは null。
int? _parseId(String id) {
  final rowId = int.tryParse(id);
  return rowId != null && '$rowId' == id ? rowId : null;
}
