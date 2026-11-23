import 'package:server/src/repository/stored_article.dart';
import 'package:server/src/repository/subscription.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('Subscription', () {
    // T1
    test('should be equal when all fields are the same', () {
      // Given: 全フィールドが同じ Subscription を2つ作る
      final a = Subscription(
        id: 's-1',
        feedUrl: feedUrlA,
        feed: rssFeed,
        lastFetchedAt: fetchedAt1,
      );
      final b = Subscription(
        id: 's-1',
        feedUrl: feedUrlA,
        feed: rssFeed,
        lastFetchedAt: fetchedAt1,
      );

      // When: 比較する
      // Then: == も hashCode も一致する
      expect(a == b, isTrue);
      expect(a.hashCode == b.hashCode, isTrue);
    });

    // T2
    test('should not be equal when only lastFetchedAt differs', () {
      // Given: lastFetchedAt だけ異なる Subscription
      final a = Subscription(
        id: 's-1',
        feedUrl: feedUrlA,
        feed: rssFeed,
        lastFetchedAt: fetchedAt1,
      );
      final b = Subscription(
        id: 's-1',
        feedUrl: feedUrlA,
        feed: rssFeed,
        lastFetchedAt: fetchedAt2,
      );

      // When: 比較する
      // Then: 等しくない
      expect(a == b, isFalse);
    });
  });

  group('StoredArticle', () {
    // T3
    test('should be equal when all fields are the same', () {
      // Given: 全フィールドが同じ StoredArticle を2つ作る
      final a = StoredArticle(
        id: 'a-1',
        feedId: 'feed-a',
        article: rss(1),
        isRead: false,
      );
      final b = StoredArticle(
        id: 'a-1',
        feedId: 'feed-a',
        article: rss(1),
        isRead: false,
      );

      // When: 比較する
      // Then: == も hashCode も一致する
      expect(a == b, isTrue);
      expect(a.hashCode == b.hashCode, isTrue);
    });

    // T4
    test('should not be equal when only isRead differs', () {
      // Given: isRead だけ異なる StoredArticle
      final a = StoredArticle(
        id: 'a-1',
        feedId: 'feed-a',
        article: rss(1),
        isRead: false,
      );
      final b = StoredArticle(
        id: 'a-1',
        feedId: 'feed-a',
        article: rss(1),
        isRead: true,
      );

      // When: 比較する
      // Then: 等しくない
      expect(a == b, isFalse);
    });

    test('should include id, feedId, isRead and article in toJson', () {
      // Given: 記事1件
      final stored = StoredArticle(
        id: '1',
        feedId: 'feed-1',
        article: rss(1),
        isRead: false,
      );

      // When: JSON に変換する
      final json = stored.toJson();

      // Then: id / feedId / isRead / article が入る
      expect(json, {
        'id': '1',
        'feedId': 'feed-1',
        'isRead': false,
        'article': rss(1).toJson(),
      });
    });
  });
}
