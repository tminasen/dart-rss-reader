import 'package:shared/shared.dart';

import 'article_repository.dart';
import 'repository_exception.dart';
import 'stored_article.dart';

final class InMemoryArticleRepository implements ArticleRepository {
  final List<StoredArticle> _articles = [];
  final Set<(String, String)> _keys = {};
  int _nextId = 1;

  @override
  Future<List<StoredArticle>> addAll(
    String feedId,
    List<Article> articles,
  ) async {
    final added = <StoredArticle>[];
    for (final a in articles) {
      final key = _uniqueKey(a);
      if (key == null || !_keys.add((feedId, key))) continue;

      added.add(
        StoredArticle(
          id: '${_nextId++}',
          feedId: feedId,
          article: a,
          isRead: false,
        ),
      );
    }
    _articles.addAll(added);
    return added;
  }

  @override
  Future<StoredArticle?> findById(String id) async {
    for (final a in _articles) {
      if (a.id == id) return a;
    }
    return null;
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

    final matched = [
      for (final (index, a) in _articles.indexed)
        if ((feedId == null || a.feedId == feedId) &&
            (!unreadOnly || !a.isRead))
          (index, a),
    ];
    matched.sort(_compareNewestFirst);
    final paged = matched.skip(offset);
    return [for (final (_, a) in limit == null ? paged : paged.take(limit)) a];
  }

  @override
  Future<StoredArticle> setRead(String id, {required bool isRead}) async {
    final index = _articles.indexWhere((a) => a.id == id);
    if (index < 0) throw ArticleNotFoundException(id);

    final old = _articles[index];
    final updated = StoredArticle(
      id: old.id,
      feedId: old.feedId,
      article: old.article,
      isRead: isRead,
    );
    _articles[index] = updated;
    return updated;
  }
}

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

/// 基準日時の新しい順。日時なしは後ろ。同じ基準日時は保存順。
int _compareNewestFirst((int, StoredArticle) x, (int, StoredArticle) y) {
  final dx = _baseDate(x.$2.article);
  final dy = _baseDate(y.$2.article);
  if (dx != null && dy != null) {
    final byDate = dy.compareTo(dx);
    if (byDate != 0) return byDate;
  } else if (dx != null) {
    return -1;
  } else if (dy != null) {
    return 1;
  }
  return x.$1.compareTo(y.$1);
}
