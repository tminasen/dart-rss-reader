import 'dart:convert';

import 'package:server/server.dart';
import 'package:server/src/repository/in_memory_article_repository.dart';
import 'package:server/src/repository/in_memory_subscription_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'repository/fixtures.dart';

void noopLogger(String message, bool isError) {}

void main() {
  group('GET /feeds', () {
    final feedsRequest = Request('GET', Uri.parse('http://localhost/feeds'));

    test('should return 200 when subscriptions are registered', () async {
      // Given: 取得済みの購読が1件登録されたリポジトリ
      final repo = InMemorySubscriptionRepository();
      await repo.add(feedUrlA);
      await repo.updateFetched('1', feed: rssFeed, fetchedAt: fetchedAt1);
      final handler = buildHandler(
        subscriptionRepository: repo,
        articleRepository: InMemoryArticleRepository(),
        logger: noopLogger,
      );

      // When: GET /feeds を処理する
      final response = await handler(feedsRequest);

      // Then: ステータスコードが 200 になる
      expect(response.statusCode, equals(200));
    });

    test(
      'should return application/json when subscriptions are registered',
      () async {
        // Given: 取得済みの購読が1件登録されたリポジトリ
        final repo = InMemorySubscriptionRepository();
        await repo.add(feedUrlA);
        await repo.updateFetched('1', feed: rssFeed, fetchedAt: fetchedAt1);
        final handler = buildHandler(
          subscriptionRepository: repo,
          articleRepository: InMemoryArticleRepository(),
          logger: noopLogger,
        );

        // When: GET /feeds を処理する
        final response = await handler(feedsRequest);

        // Then: Content-Type の MIME タイプが application/json になる
        expect(response.mimeType, equals('application/json'));
      },
    );

    test(
      'should return 200 and an empty array when no subscription exists',
      () async {
        // Given: 空のリポジトリ
        final repo = InMemorySubscriptionRepository();
        final handler = buildHandler(
          subscriptionRepository: repo,
          articleRepository: InMemoryArticleRepository(),
          logger: noopLogger,
        );

        // When: GET /feeds を処理する
        final response = await handler(feedsRequest);

        // Then: 200 で空配列が返る
        expect(response.statusCode, equals(200));
        expect(jsonDecode(await response.readAsString()), equals([]));
      },
    );

    test('should return title, url and lastFetchedAt when subscription is '
        'fetched', () async {
      // Given: 取得済みの購読が1件登録されたリポジトリ
      final repo = InMemorySubscriptionRepository();
      await repo.add(feedUrlA);
      await repo.updateFetched('1', feed: rssFeed, fetchedAt: fetchedAt1);
      final handler = buildHandler(
        subscriptionRepository: repo,
        articleRepository: InMemoryArticleRepository(),
        logger: noopLogger,
      );

      // When: GET /feeds を処理する
      final response = await handler(feedsRequest);

      // Then: title / url / lastFetchedAt を持つ1件が返る
      expect(
        jsonDecode(await response.readAsString()),
        equals([
          {
            'title': 'tminasen.dev',
            'url': 'https://tminasen.dev/rss/feed.xml',
            'lastFetchedAt': '2026-11-19T09:00:00.000Z',
          },
        ]),
      );
    });

    test('should return null title and lastFetchedAt when subscription is '
        'not fetched', () async {
      // Given: 未取得の購読が1件登録されたリポジトリ
      final repo = InMemorySubscriptionRepository();
      await repo.add(feedUrlA);
      final handler = buildHandler(
        subscriptionRepository: repo,
        articleRepository: InMemoryArticleRepository(),
        logger: noopLogger,
      );

      // When: GET /feeds を処理する
      final response = await handler(feedsRequest);

      // Then: title と lastFetchedAt が null（キーは存在する）で返る
      expect(
        jsonDecode(await response.readAsString()),
        equals([
          {
            'title': null,
            'url': 'https://tminasen.dev/rss/feed.xml',
            'lastFetchedAt': null,
          },
        ]),
      );
    });

    test('should return subscriptions in registration order when multiple '
        'subscriptions exist', () async {
      // Given: RSS と Atom の取得済み購読が登録順に2件あるリポジトリ
      final repo = InMemorySubscriptionRepository();
      await repo.add(feedUrlA);
      await repo.add(feedUrlB);
      await repo.updateFetched('1', feed: rssFeed, fetchedAt: fetchedAt1);
      await repo.updateFetched('2', feed: atomFeed, fetchedAt: fetchedAt2);
      final handler = buildHandler(
        subscriptionRepository: repo,
        articleRepository: InMemoryArticleRepository(),
        logger: noopLogger,
      );

      // When: GET /feeds を処理する
      final response = await handler(feedsRequest);

      // Then: 登録順に2件が返る
      expect(
        jsonDecode(await response.readAsString()),
        equals([
          {
            'title': 'tminasen.dev',
            'url': 'https://tminasen.dev/rss/feed.xml',
            'lastFetchedAt': '2026-11-19T09:00:00.000Z',
          },
          {
            'title': 'Example Atom',
            'url': 'https://example.com/atom.xml',
            'lastFetchedAt': '2026-11-19T10:00:00.000Z',
          },
        ]),
      );
    });

    test('should return lastFetchedAt in UTC when fetchedAt is stored as local '
        'time', () async {
      // Given: ローカル時刻で取得日時が保存された購読
      final repo = InMemorySubscriptionRepository();
      await repo.add(feedUrlA);
      await repo.updateFetched(
        '1',
        feed: rssFeed,
        fetchedAt: fetchedAt1.toLocal(),
      );
      final handler = buildHandler(
        subscriptionRepository: repo,
        articleRepository: InMemoryArticleRepository(),
        logger: noopLogger,
      );

      // When: GET /feeds を処理する
      final response = await handler(feedsRequest);

      // Then: lastFetchedAt が UTC 表記（Z 付き）で返る
      final body = jsonDecode(await response.readAsString()) as List;
      expect(
        (body[0] as Map<String, dynamic>)['lastFetchedAt'],
        equals('2026-11-19T09:00:00.000Z'),
      );
    });

    test('should return the fixed feed URL when the default repository is '
        'used', () async {
      // Given: 既定リポジトリをつないだハンドラ
      final repo = await createDefaultSubscriptionRepository();
      final handler = buildHandler(
        subscriptionRepository: repo,
        articleRepository: InMemoryArticleRepository(),
        logger: noopLogger,
      );

      // When: GET /feeds を処理する
      final response = await handler(feedsRequest);

      // Then: 固定URLの未取得1件が返る
      expect(response.statusCode, equals(200));
      expect(
        jsonDecode(await response.readAsString()),
        equals([
          {
            'title': null,
            'url': 'https://tminasen.dev/rss/feed.xml',
            'lastFetchedAt': null,
          },
        ]),
      );
    });

    group('P1: count and order are preserved', () {
      for (var n = 0; n <= 5; n++) {
        test('should return $n urls in registration order when $n '
            'subscriptions are added', () async {
          // Given: https://example.com/feed/i.xml (i = 1..n) を昇順に登録したリポジトリ
          final urls = [
            for (var i = 1; i <= n; i++) 'https://example.com/feed/$i.xml',
          ];
          final repo = InMemorySubscriptionRepository();
          for (final url in urls) {
            await repo.add(url);
          }
          final handler = buildHandler(
            subscriptionRepository: repo,
            articleRepository: InMemoryArticleRepository(),
            logger: noopLogger,
          );

          // When: GET /feeds を処理する
          final response = await handler(feedsRequest);

          // Then: 配列で、件数と URL の並びが登録と一致する
          final body = jsonDecode(await response.readAsString());
          expect(body, isA<List<dynamic>>());
          expect(body, hasLength(n));
          expect(
            (body as List).map((e) => (e as Map<String, dynamic>)['url']),
            orderedEquals(urls),
          );
        });
      }
    });
  });
}
