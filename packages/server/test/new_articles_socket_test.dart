import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/server.dart';
import 'package:server/src/feed_crawler.dart';
import 'package:server/src/repository/in_memory_article_repository.dart';
import 'package:server/src/repository/in_memory_subscription_repository.dart';
import 'package:server/src/repository/stored_article.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

import 'repository/fixtures.dart';

void noopLogger(String message, bool isError) {}

const _timeout = Duration(seconds: 5);

final stored1 = StoredArticle(
  id: '1',
  feedId: 'feed-1',
  article: rss(1),
  isRead: false,
);

final stored2 = StoredArticle(
  id: '2',
  feedId: 'feed-1',
  article: rss(2),
  isRead: false,
);

http.Response rssOk(List<String> guids) => http.Response.bytes(
  utf8.encode(
    '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>'
    '<title>tminasen.dev</title><link>https://tminasen.dev/</link>'
    '<description>desc</description>'
    '${[for (final g in guids) '<item><title>記事 $g</title>'
          '<link>https://tminasen.dev/posts/$g</link><guid>$g</guid></item>'].join()}'
    '</channel></rss>',
  ),
  200,
  headers: {'content-type': 'application/rss+xml'},
);

/// GET /articles の要素と同じ形（article は JSON 往復させた値）。
Map<String, Object?> expectedJson(StoredArticle s) => {
  'id': s.id,
  'feedId': s.feedId,
  'isRead': s.isRead,
  'article': jsonDecode(jsonEncode(s.article.toJson())),
};

Future<HttpServer> startServer(
  Stream<StoredArticle> newArticles, {
  Set<String> allowedOrigins = const {},
}) async {
  final server = await shelf_io.serve(
    buildHandler(
      subscriptionRepository: InMemorySubscriptionRepository(),
      articleRepository: InMemoryArticleRepository(),
      newArticles: newArticles,
      allowedOrigins: allowedOrigins,
      logger: noopLogger,
    ),
    InternetAddress.loopbackIPv4,
    0,
  );
  addTearDown(() => server.close(force: true));
  return server;
}

/// [condition] が真になるまで待つ（サーバー側の購読開始・解除の待ち合わせ用）。
Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(_timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met in time');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

String wsUrl(HttpServer server) => 'ws://127.0.0.1:${server.port}/ws';

void main() {
  group('GET /ws', () {
    late StreamController<StoredArticle> controller;

    setUp(() {
      controller = StreamController<StoredArticle>.broadcast();
      addTearDown(controller.close);
    });

    test('should upgrade to WebSocket when connecting', () async {
      // Given: サーバーが起動している
      final server = await startServer(controller.stream);

      // When: WebSocket で接続する
      final client = await WebSocket.connect(wsUrl(server));
      addTearDown(client.close);

      // Then: 接続が開いている
      expect(client.readyState, WebSocket.open);
    });

    test('should send new article as JSON when one is emitted', () async {
      // Given: クライアントが接続済み
      final server = await startServer(controller.stream);
      final client = await WebSocket.connect(wsUrl(server));
      addTearDown(client.close);

      // When: 新着が1件流れる
      controller.add(stored1);

      // Then: 記事 JSON がテキストメッセージで届く
      final message = await client.first.timeout(_timeout);
      expect(message, isA<String>());
      expect(jsonDecode(message as String), expectedJson(stored1));
    });

    test(
      'should send articles one by one in order when two are emitted',
      () async {
        // Given: クライアントが接続済み
        final server = await startServer(controller.stream);
        final client = await WebSocket.connect(wsUrl(server));
        addTearDown(client.close);

        // When: 新着が2件続けて流れる
        controller
          ..add(stored1)
          ..add(stored2);

        // Then: 流れた順に1件ずつ届く
        final messages = await client.take(2).toList().timeout(_timeout);
        expect(
          [for (final m in messages) (jsonDecode(m as String) as Map)['id']],
          ['1', '2'],
        );
      },
    );

    test('should send to all connected clients when one is emitted', () async {
      // Given: 2つのクライアントが接続済み
      final server = await startServer(controller.stream);
      final clientA = await WebSocket.connect(wsUrl(server));
      addTearDown(clientA.close);
      final clientB = await WebSocket.connect(wsUrl(server));
      addTearDown(clientB.close);

      // When: 新着が1件流れる
      controller.add(stored1);

      // Then: どちらにも届く
      final messageA = await clientA.first.timeout(_timeout);
      final messageB = await clientB.first.timeout(_timeout);
      expect((jsonDecode(messageA as String) as Map)['id'], '1');
      expect((jsonDecode(messageB as String) as Map)['id'], '1');
    });

    test('should keep sending to others when one client disconnects', () async {
      // Given: 2つのクライアントが接続済み
      final server = await startServer(controller.stream);
      final clientA = await WebSocket.connect(wsUrl(server));
      final clientB = await WebSocket.connect(wsUrl(server));
      addTearDown(clientB.close);

      // When: 片方が切断したあとに新着が流れる
      await clientA.close();
      controller.add(stored1);

      // Then: 残りのクライアントに届く
      final message = await clientB.first.timeout(_timeout);
      expect((jsonDecode(message as String) as Map)['id'], '1');
    });

    test('should cancel subscription when all clients disconnect', () async {
      // Given: 1人だけ接続済みで、新着 Stream が購読されている
      final cancelled = Completer<void>();
      final single = StreamController<StoredArticle>.broadcast(
        onCancel: cancelled.complete,
      );
      addTearDown(single.close);
      final server = await startServer(single.stream);
      final client = await WebSocket.connect(wsUrl(server));
      await _until(() => single.hasListener);

      // When: そのクライアントが切断する
      await client.close();

      // Then: 購読が解除される
      await cancelled.future.timeout(_timeout);
      expect(single.hasListener, isFalse);
    });

    test('should not send articles emitted before connecting', () async {
      // Given: クライアント未接続のまま新着が流れた
      final server = await startServer(controller.stream);
      controller.add(stored1);

      // When: 接続したあとに別の新着が流れる
      final client = await WebSocket.connect(wsUrl(server));
      addTearDown(client.close);
      controller.add(stored2);

      // Then: 接続後の新着だけが届く
      final message = await client.first.timeout(_timeout);
      expect((jsonDecode(message as String) as Map)['id'], '2');
    });

    test('should reject connection when origin is not allowed', () async {
      // Given: 許可 Origin を限定したサーバー
      final server = await startServer(
        controller.stream,
        allowedOrigins: {'http://localhost:8081'},
      );

      // When: 許可されていない Origin から接続する
      final connecting = WebSocket.connect(
        wsUrl(server),
        headers: {'origin': 'http://evil.example'},
      );

      // Then: ハンドシェイクが拒否される
      await expectLater(connecting, throwsA(isA<WebSocketException>()));
    });

    test('should accept connection when origin is allowed', () async {
      // Given: 許可 Origin を限定したサーバー
      final server = await startServer(
        controller.stream,
        allowedOrigins: {'http://localhost:8081'},
      );

      // When: 許可された Origin から接続する
      final client = await WebSocket.connect(
        wsUrl(server),
        headers: {'origin': 'http://localhost:8081'},
      );
      addTearDown(client.close);

      // Then: 接続が開いている
      expect(client.readyState, WebSocket.open);
    });

    test('should deliver articles found by crawling to clients', () async {
      // Given: 購読済みのフィードを巡回するクローラーと、その新着を配信するサーバー
      final subscriptions = InMemorySubscriptionRepository();
      final articles = InMemoryArticleRepository();
      await subscriptions.add(feedUrlA);
      final crawler = FeedCrawler(
        subscriptions: subscriptions,
        articles: articles,
        client: FeedClient(MockClient((request) async => rssOk(['post-1']))),
        feedUrls: [feedUrlA],
        now: () => DateTime.utc(2026, 11, 23, 9),
      );
      addTearDown(crawler.close);
      final server = await shelf_io.serve(
        buildHandler(
          subscriptionRepository: subscriptions,
          articleRepository: articles,
          newArticles: crawler.newArticles,
          logger: noopLogger,
        ),
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => server.close(force: true));
      final client = await WebSocket.connect(wsUrl(server));
      addTearDown(client.close);

      // When: 巡回する
      await crawler.crawl();

      // Then: 新着記事が届く
      final message =
          jsonDecode(await client.first.timeout(_timeout) as String)
              as Map<String, Object?>;
      final article = message['article'] as Map<String, Object?>;
      expect(message['feedId'], '1');
      expect(message['isRead'], false);
      expect(article['guid'], 'post-1');
      expect(article['format'], 'rss');
    });
  });
}
