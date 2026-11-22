import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_app/src/api/api_exception.dart';
import 'package:web_app/src/api/feeds_api_client.dart';

final baseUrl = Uri.parse('http://localhost:8080');

final summaryJson = {
  'title': 'tminasen.dev',
  'url': 'https://tminasen.dev/rss/feed.xml',
  'lastFetchedAt': '2026-11-19T09:00:00.000Z',
  'articleCount': 10,
};

final summaryA = FeedSummary(
  title: 'tminasen.dev',
  url: 'https://tminasen.dev/rss/feed.xml',
  lastFetchedAt: DateTime.utc(2026, 11, 19, 9),
  articleCount: 10,
);

void main() {
  group('FeedsApiClient.fetchFeeds', () {
    test(
      'should convert a JSON array to FeedSummary list when status is 200',
      () async {
        // Given: 200 で JSON 配列を返す MockClient
        final mock = MockClient(
          (_) async => http.Response(jsonEncode([summaryJson]), 200),
        );

        // When: フィード一覧を取得する
        final feeds = await FeedsApiClient(mock, baseUrl: baseUrl).fetchFeeds();

        // Then: FeedSummary のリストになる
        expect(feeds, equals([summaryA]));
      },
    );

    test('should send GET to {baseUrl}/feeds when fetching feeds', () async {
      // Given: リクエストを記録し、200 と空配列を返す MockClient
      final requests = <http.Request>[];
      final mock = MockClient((request) async {
        requests.add(request);
        return http.Response('[]', 200);
      });

      // When: フィード一覧を取得する
      await FeedsApiClient(mock, baseUrl: baseUrl).fetchFeeds();

      // Then: GET http://localhost:8080/feeds が1件送られる
      expect(requests, hasLength(1));
      expect(requests.single.method, equals('GET'));
      expect(
        requests.single.url,
        equals(Uri.parse('http://localhost:8080/feeds')),
      );
    });

    test('should return an empty list when the JSON array is empty', () async {
      // Given: 200 で空配列を返す MockClient
      final mock = MockClient((_) async => http.Response('[]', 200));

      // When: フィード一覧を取得する
      final feeds = await FeedsApiClient(mock, baseUrl: baseUrl).fetchFeeds();

      // Then: 空リストが返る
      expect(feeds, isEmpty);
    });

    test(
      'should throw ApiHttpStatusException when status is not 2xx',
      () async {
        // Given: 500 を返す MockClient
        final mock = MockClient((_) async => http.Response('', 500));

        // When: フィード一覧を取得する
        final future = FeedsApiClient(mock, baseUrl: baseUrl).fetchFeeds();

        // Then: ステータスコード付きの ApiHttpStatusException が投げられる
        await expectLater(
          future,
          throwsA(
            isA<ApiHttpStatusException>().having(
              (e) => e.statusCode,
              'statusCode',
              500,
            ),
          ),
        );
      },
    );

    test('should throw ApiConnectionException when connection fails', () async {
      // Given: ClientException を投げる MockClient
      final mock = MockClient(
        (_) async => throw http.ClientException('connection refused'),
      );

      // When: フィード一覧を取得する
      final future = FeedsApiClient(mock, baseUrl: baseUrl).fetchFeeds();

      // Then: ApiConnectionException が投げられる
      await expectLater(future, throwsA(isA<ApiConnectionException>()));
    });

    test('should throw ApiTimeoutException when request times out', () async {
      // Given: 完了しないレスポンスを返す MockClient と 10ms のタイムアウト
      final mock = MockClient((_) => Completer<http.Response>().future);
      final client = FeedsApiClient(
        mock,
        baseUrl: baseUrl,
        timeout: const Duration(milliseconds: 10),
      );

      // When: フィード一覧を取得する
      final future = client.fetchFeeds();

      // Then: ApiTimeoutException が投げられる
      await expectLater(future, throwsA(isA<ApiTimeoutException>()));
    });

    test('should throw ApiFormatException when body is not JSON', () async {
      // Given: JSON でない本文を 200 で返す MockClient
      final mock = MockClient((_) async => http.Response('not json', 200));

      // When: フィード一覧を取得する
      final future = FeedsApiClient(mock, baseUrl: baseUrl).fetchFeeds();

      // Then: ApiFormatException が投げられる
      await expectLater(future, throwsA(isA<ApiFormatException>()));
    });

    test('should throw ApiFormatException when JSON is not an array', () async {
      // Given: 配列でない JSON を 200 で返す MockClient
      final mock = MockClient((_) async => http.Response('{"url":"x"}', 200));

      // When: フィード一覧を取得する
      final future = FeedsApiClient(mock, baseUrl: baseUrl).fetchFeeds();

      // Then: ApiFormatException が投げられる
      await expectLater(future, throwsA(isA<ApiFormatException>()));
    });

    test('should throw ApiFormatException when an element lacks url', () async {
      // Given: url の無い要素を含む JSON を 200 で返す MockClient
      final mock = MockClient(
        (_) async => http.Response(
          '[{"title":null,"lastFetchedAt":null,"articleCount":0}]',
          200,
        ),
      );

      // When: フィード一覧を取得する
      final future = FeedsApiClient(mock, baseUrl: baseUrl).fetchFeeds();

      // Then: ApiFormatException が投げられる
      await expectLater(future, throwsA(isA<ApiFormatException>()));
    });
  });
}
