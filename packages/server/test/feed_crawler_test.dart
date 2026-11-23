import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/server.dart';
import 'package:server/src/feed_crawler.dart';
import 'package:server/src/repository/in_memory_article_repository.dart';
import 'package:server/src/repository/in_memory_subscription_repository.dart';
import 'package:server/src/repository/stored_article.dart';
import 'package:server/src/repository/subscription.dart';
import 'package:server/src/repository/subscription_repository.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'repository/fixtures.dart';

final now = DateTime.utc(2026, 11, 23, 9);

String rssXml(List<String> guids) =>
    '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>'
    '<title>tminasen.dev</title><link>https://tminasen.dev/</link>'
    '<description>desc</description>'
    '${[for (final g in guids) '<item><title>記事 $g</title>'
          '<link>https://tminasen.dev/posts/$g</link><guid>$g</guid></item>'].join()}'
    '</channel></rss>';

http.Response rssOk(List<String> guids) => http.Response.bytes(
  utf8.encode(rssXml(guids)),
  200,
  headers: {'content-type': 'application/rss+xml'},
);

/// 要求したURLを [requested] に記録し、[byUrl] の応答を返す。未定義のURLは404。
/// [byUrl] は要求ごとに読むので、テスト中に差し替えられる。
MockClient mockFeeds(
  Map<String, http.Response> byUrl,
  List<String> requested,
) => MockClient((request) async {
  requested.add(request.url.toString());
  return byUrl[request.url.toString()] ?? http.Response('', 404);
});

/// [updateFetched] だけ失敗する購読リポジトリ。残りは [_inner] に委譲する。
final class FailingUpdateSubscriptionRepository
    implements SubscriptionRepository {
  FailingUpdateSubscriptionRepository(this._inner);

  final InMemorySubscriptionRepository _inner;

  @override
  Future<Subscription> add(String feedUrl) => _inner.add(feedUrl);

  @override
  Future<Subscription?> findById(String id) => _inner.findById(id);

  @override
  Future<Subscription?> findByUrl(String feedUrl) => _inner.findByUrl(feedUrl);

  @override
  Future<List<Subscription>> findAll() => _inner.findAll();

  @override
  Future<Subscription> updateFetched(
    String id, {
    required Feed feed,
    required DateTime fetchedAt,
  }) => Future.error(StateError('boom'));
}

List<String> guidsOf(List<StoredArticle> articles) => [
  for (final a in articles) (a.article as RssArticle).guid!,
];

void main() {
  late InMemorySubscriptionRepository subscriptions;
  late InMemoryArticleRepository articles;
  late Map<String, http.Response> responses;
  late List<String> requested;
  late List<(String, Object)> errors;

  FeedCrawler newCrawler(List<String> feedUrls) => FeedCrawler(
    subscriptions: subscriptions,
    articles: articles,
    client: FeedClient(mockFeeds(responses, requested)),
    feedUrls: feedUrls,
    now: () => now,
    onError: (url, error, _) => errors.add((url, error)),
  );

  setUp(() async {
    subscriptions = InMemorySubscriptionRepository();
    articles = InMemoryArticleRepository();
    responses = {};
    requested = [];
    errors = [];
    await subscriptions.add(feedUrlA);
  });

  group('FeedCrawler.crawl', () {
    test('should save fetched articles when the feed is fetched', () async {
      // Given: feedUrlA が2件の記事を返す
      responses[feedUrlA] = rssOk(['post-1', 'post-2']);
      final crawler = newCrawler([feedUrlA]);
      addTearDown(crawler.close);

      // When: 巡回する
      await crawler.crawl();

      // Then: 2件が保存される
      expect(guidsOf(await articles.find(feedId: '1')), ['post-1', 'post-2']);
    });

    test(
      'should record feed and fetched time when the feed is fetched',
      () async {
        // Given: feedUrlA が記事を返す
        responses[feedUrlA] = rssOk(['post-1', 'post-2']);
        final crawler = newCrawler([feedUrlA]);
        addTearDown(crawler.close);

        // When: 巡回する
        await crawler.crawl();

        // Then: 購読にフィード情報と取得日時が記録される
        final subscription = await subscriptions.findById('1');
        expect(subscription!.feed!.title, equals('tminasen.dev'));
        expect(subscription.lastFetchedAt, equals(now));
      },
    );

    test('should emit saved articles to newArticles when crawled', () async {
      // Given: 新着を購読済みのクローラー
      responses[feedUrlA] = rssOk(['post-1', 'post-2']);
      final crawler = newCrawler([feedUrlA]);
      addTearDown(crawler.close);
      final emitted = <String>[];
      crawler.newArticles.listen((a) => emitted.addAll(guidsOf([a])));

      // When: 巡回する
      await crawler.crawl();
      await pumpEventQueue();

      // Then: 保存した記事が順に流れる
      expect(emitted, ['post-1', 'post-2']);
    });

    test(
      'should not save duplicates when crawled twice with the same feed',
      () async {
        // Given: 同じ内容を返すフィード
        responses[feedUrlA] = rssOk(['post-1', 'post-2']);
        final crawler = newCrawler([feedUrlA]);
        addTearDown(crawler.close);

        // When: 2回巡回する
        await crawler.crawl();
        await crawler.crawl();

        // Then: 記事は2件のまま
        expect(await articles.find(feedId: '1'), hasLength(2));
      },
    );

    test(
      'should save and emit only new articles when the feed gains an article',
      () async {
        // Given: 1回目の巡回済みで、2回目は記事が1件増える
        responses[feedUrlA] = rssOk(['post-1', 'post-2']);
        final crawler = newCrawler([feedUrlA]);
        addTearDown(crawler.close);
        await crawler.crawl();
        final emitted = <String>[];
        crawler.newArticles.listen((a) => emitted.addAll(guidsOf([a])));
        responses[feedUrlA] = rssOk(['post-1', 'post-2', 'post-3']);

        // When: 2回目の巡回をする
        await crawler.crawl();
        await pumpEventQueue();

        // Then: 増えた1件だけが流れ、保存は3件になる
        expect(emitted, ['post-3']);
        expect(await articles.find(feedId: '1'), hasLength(3));
      },
    );

    for (var seed = 0; seed < 100; seed++) {
      test('should save and emit each article exactly once '
          'when crawled with random feeds (seed $seed)', () async {
        // Given: 乱数で決めた巡回列（回数1〜5、各回は post-1〜post-20 の部分集合）
        final random = Random(seed);
        final roundCount = 1 + random.nextInt(5);
        final rounds = [
          for (var i = 0; i < roundCount; i++)
            [
              for (var n = 1; n <= 20; n++)
                if (random.nextBool()) 'post-$n',
            ],
        ];
        final crawler = newCrawler([feedUrlA]);
        addTearDown(crawler.close);
        final emitted = <String>[];
        crawler.newArticles.listen((a) => emitted.addAll(guidsOf([a])));

        // When: 順に巡回する
        for (final guids in rounds) {
          responses[feedUrlA] = rssOk(guids);
          await crawler.crawl();
        }
        await pumpEventQueue();

        // Then: 保存・通知とも、和集合の各記事が1回だけ
        final union = {for (final r in rounds) ...r};
        final saved = guidsOf(await articles.find(feedId: '1'));
        expect(saved.toSet(), equals(union));
        expect(saved, hasLength(union.length));
        expect(emitted.toSet(), equals(saved.toSet()));
        expect(emitted, hasLength(emitted.toSet().length));
      });
    }

    test(
      'should save each feed separately when multiple feeds are registered',
      () async {
        // Given: 2つの購読と、それぞれの記事
        await subscriptions.add(feedUrlB);
        responses[feedUrlA] = rssOk(['post-1', 'post-2']);
        responses[feedUrlB] = rssOk(['b-1']);
        final crawler = newCrawler([feedUrlA, feedUrlB]);
        addTearDown(crawler.close);

        // When: 巡回する
        await crawler.crawl();

        // Then: フィードごとに保存される
        expect(await articles.find(feedId: '1'), hasLength(2));
        expect(guidsOf(await articles.find(feedId: '2')), ['b-1']);
      },
    );

    test(
      'should save other feeds and report error when a feed returns HTTP error',
      () async {
        // Given: A が500、B が正常
        await subscriptions.add(feedUrlB);
        responses[feedUrlA] = http.Response('', 500);
        responses[feedUrlB] = rssOk(['b-1']);
        final crawler = newCrawler([feedUrlA, feedUrlB]);
        addTearDown(crawler.close);

        // When: 巡回する
        await crawler.crawl();

        // Then: 例外を投げずに B が保存され、A の失敗が通知される
        expect(guidsOf(await articles.find(feedId: '2')), ['b-1']);
        expect(errors, hasLength(1));
        expect(errors.single.$1, equals(feedUrlA));
        expect(errors.single.$2, isA<FeedHttpStatusException>());
      },
    );

    test(
      'should save other feeds and report error when a feed cannot be parsed',
      () async {
        // Given: A が XML でない本文、B が正常
        await subscriptions.add(feedUrlB);
        responses[feedUrlA] = http.Response('not xml', 200);
        responses[feedUrlB] = rssOk(['b-1']);
        final crawler = newCrawler([feedUrlA, feedUrlB]);
        addTearDown(crawler.close);

        // When: 巡回する
        await crawler.crawl();

        // Then: 例外を投げずに B が保存され、A の失敗が通知される
        expect(guidsOf(await articles.find(feedId: '2')), ['b-1']);
        expect(errors, hasLength(1));
        expect(errors.single.$1, equals(feedUrlA));
        expect(errors.single.$2, isA<FeedParseException>());
      },
    );

    test(
      'should not fetch subscriptions outside feedUrls when crawled',
      () async {
        // Given: 設定外の購読が登録されている
        const feedUrlOld = 'https://old.example.com/feed.xml';
        await subscriptions.add(feedUrlOld);
        responses[feedUrlA] = rssOk(['post-1']);
        responses[feedUrlOld] = rssOk(['old-1']);
        final crawler = newCrawler([feedUrlA]);
        addTearDown(crawler.close);

        // When: 巡回する
        await crawler.crawl();

        // Then: 設定のURLだけを取得し、旧URLの記事は保存されない
        expect(requested, [feedUrlA]);
        expect(await articles.find(feedId: '2'), isEmpty);
      },
    );

    test(
      'should not save or record anything when the feed is not modified',
      () async {
        // Given: 304 を返すフィード
        responses[feedUrlA] = http.Response('', 304);
        final crawler = newCrawler([feedUrlA]);
        addTearDown(crawler.close);
        final emitted = <String>[];
        crawler.newArticles.listen((a) => emitted.addAll(guidsOf([a])));

        // When: 巡回する
        await crawler.crawl();
        await pumpEventQueue();

        // Then: 保存・記録・通知・エラーのいずれもない
        expect(await articles.find(feedId: '1'), isEmpty);
        expect((await subscriptions.findById('1'))!.lastFetchedAt, isNull);
        expect(emitted, isEmpty);
        expect(errors, isEmpty);
      },
    );

    test(
      'should emit saved articles and report error when recording fetch fails',
      () async {
        // Given: updateFetched だけ失敗する購読リポジトリ
        final failing = FailingUpdateSubscriptionRepository(subscriptions);
        responses[feedUrlA] = rssOk(['post-1', 'post-2']);
        final crawler = FeedCrawler(
          subscriptions: failing,
          articles: articles,
          client: FeedClient(mockFeeds(responses, requested)),
          feedUrls: [feedUrlA],
          now: () => now,
          onError: (url, error, _) => errors.add((url, error)),
        );
        addTearDown(crawler.close);
        final emitted = <String>[];
        crawler.newArticles.listen((a) => emitted.addAll(guidsOf([a])));

        // When: 巡回する
        await crawler.crawl();
        await pumpEventQueue();

        // Then: 保存した記事は流れ、失敗が通知される
        expect(emitted, ['post-1', 'post-2']);
        expect(errors, hasLength(1));
        expect(errors.single.$1, equals(feedUrlA));
        expect(errors.single.$2, isA<StateError>());
      },
    );

    test('should skip feedUrls that are not registered when crawled', () async {
      // Given: feedUrlB は購読として未登録
      responses[feedUrlA] = rssOk(['post-1']);
      final crawler = newCrawler([feedUrlA, feedUrlB]);
      addTearDown(crawler.close);

      // When: 巡回する
      await crawler.crawl();

      // Then: 登録済みの A だけ取得し、エラーにならない
      expect(requested, [feedUrlA]);
      expect(errors, isEmpty);
      expect(await articles.find(feedId: '1'), hasLength(1));
    });
  });
}
