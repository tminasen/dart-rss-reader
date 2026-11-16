import 'dart:async';
import 'dart:convert';
import 'dart:io' show HandshakeException;

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/server.dart';
import 'package:test/test.dart';

const rssXml =
    '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>'
    '<title>Example Feed</title><link>https://example.com</link>'
    '<description>desc</description>'
    '<item><title>First post</title></item>'
    '<item><title>Second post</title></item>'
    '</channel></rss>';

const japaneseXml =
    '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>'
    '<title>Example Feed</title><link>https://example.com</link>'
    '<description>desc</description>'
    '<item><title>日本語の記事</title></item>'
    '</channel></rss>';

const lastModifiedValue = 'Mon, 16 Nov 2026 12:00:00 GMT';

final feedUrl = Uri.parse('https://example.com/feed.xml');

http.Response rssResponse(
  String body, {
  int status = 200,
  Map<String, String> headers = const {},
}) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {'content-type': 'application/rss+xml', ...headers},
);

FeedClient client(
  Future<http.Response> Function(http.Request) handler, {
  Duration? timeout,
}) => timeout == null
    ? FeedClient(MockClient(handler))
    : FeedClient(MockClient(handler), timeout: timeout);

void main() {
  group('FeedClient.fetch', () {
    test('should return feed and articles when response is 200', () async {
      // Given: 200 で RSS を返す MockClient
      final feedClient = client((_) async => rssResponse(rssXml));

      // When: フィードを取得する
      final result = await feedClient.fetch(feedUrl);

      // Then: FeedUpdated でフィードと記事が返る
      expect(result, isA<FeedUpdated>());
      final updated = result as FeedUpdated;
      expect(updated.feed.title, equals('Example Feed'));
      expect(
        updated.articles.map((a) => a.title),
        equals(['First post', 'Second post']),
      );
    });

    test('should send GET to the given url when fetch is called', () async {
      // Given: リクエストを記録する MockClient
      final requests = <http.Request>[];
      final feedClient = client((request) async {
        requests.add(request);
        return rssResponse(rssXml);
      });

      // When: フィードを取得する
      await feedClient.fetch(feedUrl);

      // Then: 指定 URL へ GET が1回送られる
      expect(requests.single.method, equals('GET'));
      expect(requests.single.url, equals(feedUrl));
    });

    test('should decode body as UTF-8 when charset is not specified', () async {
      // Given: charset なしで日本語タイトルを返す MockClient
      final feedClient = client((_) async => rssResponse(japaneseXml));

      // When: フィードを取得する
      final result = await feedClient.fetch(feedUrl);

      // Then: 日本語タイトルが文字化けせず読める
      expect((result as FeedUpdated).articles.single.title, equals('日本語の記事'));
    });

    test('should return etag and lastModified when headers exist', () async {
      // Given: ETag / Last-Modified ヘッダー付きで返す MockClient
      final feedClient = client(
        (_) async => rssResponse(
          rssXml,
          headers: {'etag': '"v2"', 'last-modified': lastModifiedValue},
        ),
      );

      // When: フィードを取得する
      final result = await feedClient.fetch(feedUrl) as FeedUpdated;

      // Then: ヘッダー値がそのまま返る
      expect(result.etag, equals('"v2"'));
      expect(result.lastModified, equals('Mon, 16 Nov 2026 12:00:00 GMT'));
    });

    test(
      'should return null etag and lastModified when headers are absent',
      () async {
        // Given: ヘッダーなしで返す MockClient
        final feedClient = client((_) async => rssResponse(rssXml));

        // When: フィードを取得する
        final result = await feedClient.fetch(feedUrl) as FeedUpdated;

        // Then: etag / lastModified は null
        expect(result.etag, isNull);
        expect(result.lastModified, isNull);
      },
    );

    test('should send If-None-Match when etag is given', () async {
      // Given: リクエストを記録する MockClient
      final requests = <http.Request>[];
      final feedClient = client((request) async {
        requests.add(request);
        return rssResponse(rssXml);
      });

      // When: etag を指定して取得する
      await feedClient.fetch(feedUrl, etag: '"v1"');

      // Then: If-None-Match ヘッダーが送られる
      expect(requests.single.headers['If-None-Match'], equals('"v1"'));
    });

    test('should send If-Modified-Since when lastModified is given', () async {
      // Given: リクエストを記録する MockClient
      final requests = <http.Request>[];
      final feedClient = client((request) async {
        requests.add(request);
        return rssResponse(rssXml);
      });

      // When: lastModified を指定して取得する
      await feedClient.fetch(feedUrl, lastModified: lastModifiedValue);

      // Then: If-Modified-Since ヘッダーが送られる
      expect(
        requests.single.headers['If-Modified-Since'],
        equals('Mon, 16 Nov 2026 12:00:00 GMT'),
      );
    });

    test(
      'should not send conditional headers when no condition is given',
      () async {
        // Given: リクエストを記録する MockClient
        final requests = <http.Request>[];
        final feedClient = client((request) async {
          requests.add(request);
          return rssResponse(rssXml);
        });

        // When: 条件なしで取得する
        await feedClient.fetch(feedUrl);

        // Then: 条件付きヘッダーは送られない
        expect(requests.single.headers, isNot(contains('If-None-Match')));
        expect(requests.single.headers, isNot(contains('If-Modified-Since')));
      },
    );

    test('should return FeedNotModified when response is 304', () async {
      // Given: 304 を返す MockClient
      final feedClient = client((_) async => http.Response('', 304));

      // When: etag 付きで取得する
      final result = await feedClient.fetch(feedUrl, etag: '"v1"');

      // Then: FeedNotModified が返る（例外は投げない）
      expect(result, isA<FeedNotModified>());
    });

    test('should throw FeedTimeoutException when request times out', () async {
      // Given: 完了しないレスポンスを返す MockClient と 10ms のタイムアウト
      final feedClient = client(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 10),
      );

      // When: フィードを取得する
      final future = feedClient.fetch(feedUrl);

      // Then: FeedTimeoutException が投げられる
      await expectLater(future, throwsA(isA<FeedTimeoutException>()));
    });

    test(
      'should throw FeedConnectionException when connection fails',
      () async {
        // Given: 接続失敗を投げる MockClient
        final feedClient = client(
          (_) async =>
              throw http.ClientException('Connection refused', feedUrl),
        );

        // When: フィードを取得する
        final future = feedClient.fetch(feedUrl);

        // Then: FeedConnectionException が投げられる
        await expectLater(future, throwsA(isA<FeedConnectionException>()));
      },
    );

    test(
      'should throw FeedConnectionException when TLS handshake fails',
      () async {
        // Given: TLS ハンドシェイク失敗を投げる MockClient
        final feedClient = client(
          (_) async => throw const HandshakeException('handshake failed'),
        );

        // When: フィードを取得する
        final future = feedClient.fetch(feedUrl);

        // Then: FeedConnectionException が投げられる
        await expectLater(future, throwsA(isA<FeedConnectionException>()));
      },
    );

    test('should throw FeedHttpStatusException when response is 404', () async {
      // Given: 404 を返す MockClient
      final feedClient = client((_) async => http.Response('Not Found', 404));

      // When: フィードを取得する
      final future = feedClient.fetch(feedUrl);

      // Then: ステータスコード 404 を持つ FeedHttpStatusException が投げられる
      await expectLater(
        future,
        throwsA(
          isA<FeedHttpStatusException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('should throw FeedHttpStatusException when response is 500', () async {
      // Given: 500 を返す MockClient
      final feedClient = client(
        (_) async => http.Response('Internal Server Error', 500),
      );

      // When: フィードを取得する
      final future = feedClient.fetch(feedUrl);

      // Then: ステータスコード 500 を持つ FeedHttpStatusException が投げられる
      await expectLater(
        future,
        throwsA(
          isA<FeedHttpStatusException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('should throw FeedHttpStatusException when response is 300', () async {
      // Given: 300 を返す MockClient
      final feedClient = client((_) async => http.Response('', 300));

      // When: フィードを取得する
      final future = feedClient.fetch(feedUrl);

      // Then: ステータスコード 300 を持つ FeedHttpStatusException が投げられる
      await expectLater(
        future,
        throwsA(
          isA<FeedHttpStatusException>().having(
            (e) => e.statusCode,
            'statusCode',
            300,
          ),
        ),
      );
    });

    test('should treat 299 as success when response is 299', () async {
      // Given: 299 で RSS を返す MockClient
      final feedClient = client((_) async => rssResponse(rssXml, status: 299));

      // When: フィードを取得する
      final result = await feedClient.fetch(feedUrl);

      // Then: FeedUpdated が返る
      expect(result, isA<FeedUpdated>());
      expect((result as FeedUpdated).feed.title, equals('Example Feed'));
    });

    group('P1: any status in 300..599 except 304', () {
      for (var status = 300; status <= 599; status++) {
        if (status == 304) continue;
        test('should throw FeedHttpStatusException with $status', () async {
          // Given: 該当ステータスを返す MockClient
          final feedClient = client((_) async => http.Response('', status));

          // When: フィードを取得する
          final future = feedClient.fetch(feedUrl);

          // Then: 同じステータスコードを保持する FeedHttpStatusException
          await expectLater(
            future,
            throwsA(
              isA<FeedHttpStatusException>().having(
                (e) => e.statusCode,
                'statusCode',
                status,
              ),
            ),
          );
        });
      }
    });

    test('should throw FeedParseException when body is not XML', () async {
      // Given: XML でない本文を返す MockClient
      final feedClient = client((_) async => rssResponse('not xml'));

      // When: フィードを取得する
      final future = feedClient.fetch(feedUrl);

      // Then: FeedParseException が投げられる（RssParseException は漏れない）
      await expectLater(future, throwsA(isA<FeedParseException>()));
    });

    test(
      'should throw FeedParseException when body is invalid UTF-8',
      () async {
        // Given: 不正な UTF-8 のバイト列を返す MockClient
        final feedClient = client(
          (_) async => http.Response.bytes([0xFF, 0xFE, 0xFD], 200),
        );

        // When: フィードを取得する
        final future = feedClient.fetch(feedUrl);

        // Then: FeedParseException が投げられる
        await expectLater(future, throwsA(isA<FeedParseException>()));
      },
    );
  });
}
