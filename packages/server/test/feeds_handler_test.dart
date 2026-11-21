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
            'articleCount': 0,
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
            'articleCount': 0,
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
            'articleCount': 0,
          },
          {
            'title': 'Example Atom',
            'url': 'https://example.com/atom.xml',
            'lastFetchedAt': '2026-11-19T10:00:00.000Z',
            'articleCount': 0,
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
            'articleCount': 0,
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

    group('articleCount', () {
      late InMemorySubscriptionRepository subRepo;
      late InMemoryArticleRepository articleRepo;
      late Handler handler;

      setUp(() {
        subRepo = InMemorySubscriptionRepository();
        articleRepo = InMemoryArticleRepository();
        handler = buildHandler(
          subscriptionRepository: subRepo,
          articleRepository: articleRepo,
          logger: noopLogger,
        );
      });

      Future<List<Map<String, dynamic>>> getFeeds() async {
        final response = await handler(feedsRequest);
        return (jsonDecode(await response.readAsString()) as List)
            .cast<Map<String, dynamic>>();
      }

      test(
        'should return articleCount 3 when the feed has 3 articles',
        () async {
          // Given: 取得済みの購読1件と、そのフィードの記事3件
          await subRepo.add(feedUrlA);
          await subRepo.updateFetched(
            '1',
            feed: rssFeed,
            fetchedAt: fetchedAt1,
          );
          await articleRepo.addAll('1', [rss(1), rss(2), rss(3)]);

          // When: GET /feeds を処理する
          final body = await getFeeds();

          // Then: articleCount が 3 で返る
          expect(
            body,
            equals([
              {
                'title': 'tminasen.dev',
                'url': feedUrlA,
                'lastFetchedAt': '2026-11-19T09:00:00.000Z',
                'articleCount': 3,
              },
            ]),
          );
        },
      );

      test(
        'should return articleCount 0 when the feed has no articles',
        () async {
          // Given: 取得済みの購読1件（記事は追加しない）
          await subRepo.add(feedUrlA);
          await subRepo.updateFetched(
            '1',
            feed: rssFeed,
            fetchedAt: fetchedAt1,
          );

          // When: GET /feeds を処理する
          final body = await getFeeds();

          // Then: articleCount が 0 で返る
          expect(
            body,
            equals([
              {
                'title': 'tminasen.dev',
                'url': feedUrlA,
                'lastFetchedAt': '2026-11-19T09:00:00.000Z',
                'articleCount': 0,
              },
            ]),
          );
        },
      );

      test(
        'should count articles per feed when multiple feeds exist',
        () async {
          // Given: 購読2件と、フィードごとに異なる件数の記事
          await subRepo.add(feedUrlA);
          await subRepo.add(feedUrlB);
          await articleRepo.addAll('1', [rss(1), rss(2)]);
          await articleRepo.addAll('2', [rss(3)]);

          // When: GET /feeds を処理する
          final body = await getFeeds();

          // Then: 登録順に [2, 1] が返る
          expect(body.map((e) => e['articleCount']), equals([2, 1]));
        },
      );

      test('should count read articles when some articles are read', () async {
        // Given: 記事2件のうち1件を既読にしたフィード
        await subRepo.add(feedUrlA);
        final added = await articleRepo.addAll('1', [rss(1), rss(2)]);
        await articleRepo.setRead(added.first.id, isRead: true);

        // When: GET /feeds を処理する
        final body = await getFeeds();

        // Then: 既読を含めた 2 が返る
        expect(body[0]['articleCount'], equals(2));
      });

      group('P2: count conservation', () {
        const subscriptionCounts = [1, 2, 3];
        const articleCounts = [0, 1, 5];

        // 購読数 n に対し、各購読の記事数 c_i ∈ {0, 1, 5} の全組み合わせ。
        List<List<int>> combinations(int n) => n == 0
            ? [[]]
            : [
                for (final rest in combinations(n - 1))
                  for (final c in articleCounts) [...rest, c],
              ];

        for (final n in subscriptionCounts) {
          for (final counts in combinations(n)) {
            test('should return $counts in registration order when '
                '$n subscriptions have those articles', () async {
              // Given: 購読 n 件に、購読ごとに重ならない記事を counts[i] 件追加
              var next = 1;
              for (var i = 0; i < n; i++) {
                await subRepo.add('https://example.com/feed/$i.xml');
                await articleRepo.addAll('${i + 1}', [
                  for (var k = 0; k < counts[i]; k++) rss(next++),
                ]);
              }

              // When: GET /feeds を処理する
              final body = await getFeeds();

              // Then: articleCount が登録順に counts と一致し、合計も一致する
              final actual = body.map((e) => e['articleCount']).toList();
              expect(actual, equals(counts));
              expect(
                actual.fold<int>(0, (a, b) => a + (b as int)),
                equals(counts.fold<int>(0, (a, b) => a + b)),
              );
            });
          }
        }
      });
    });
  });
}
