import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_app/src/api/api_exception.dart';
import 'package:web_app/src/api/articles_api_client.dart';

final baseUrl = Uri.parse('http://localhost:8080');

final rssArticleA = RssArticle(
  title: 'Angularを使ってボードゲームの得点計算ツールを作った話',
  link: 'https://tminasen.dev/blog/1',
  pubDate: DateTime(2026, 4, 14),
  enclosure: const RssEnclosure(
    url: 'https://tminasen.dev/images/1.png',
    length: 0,
    type: 'image/png',
  ),
);

final atomArticleA = AtomArticle(
  id: 'atom-1',
  title: 'Atom記事',
  link: 'https://example.com/atom/1',
  published: DateTime(2026, 1, 5),
  updated: DateTime(2026, 1, 6),
);

final unreadItemA = ArticleItem(
  id: 'a-1',
  feedId: 'f-1',
  isRead: false,
  article: rssArticleA,
);

final unreadItemC = ArticleItem(
  id: 'a-3',
  feedId: 'f-1',
  isRead: false,
  article: atomArticleA,
);

final itemAJson = <String, dynamic>{
  'id': 'a-1',
  'feedId': 'f-1',
  'isRead': false,
  'article': rssArticleA.toJson(),
};

final itemCJson = <String, dynamic>{
  'id': 'a-3',
  'feedId': 'f-1',
  'isRead': false,
  'article': atomArticleA.toJson(),
};

void main() {
  group('ArticlesApiClient.fetchArticles', () {
    // T19
    test(
      'should send GET {baseUrl}/articles?limit=100 and return ArticleItem list',
      () async {
        // Given: 200 で items に itemAJson, itemCJson を返す MockClient
        final requests = <http.Request>[];
        final mock = MockClient((request) async {
          requests.add(request);
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'items': [itemAJson, itemCJson],
                'limit': 100,
                'offset': 0,
              }),
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        // When: 記事一覧を取得する
        final items = await ArticlesApiClient(
          mock,
          baseUrl: baseUrl,
        ).fetchArticles();

        // Then: GET /articles?limit=100 が送られ [unreadItemA, unreadItemC] が返る
        expect(requests, hasLength(1));
        expect(requests.single.method, equals('GET'));
        expect(
          requests.single.url,
          equals(Uri.parse('http://localhost:8080/articles?limit=100')),
        );
        expect(items, equals([unreadItemA, unreadItemC]));
      },
    );

    // T20
    test('should return empty list when items array is empty', () async {
      // Given: 200 で items が空配列のレスポンスを返す MockClient
      final mock = MockClient(
        (_) async => http.Response(
          jsonEncode({'items': [], 'limit': 100, 'offset': 0}),
          200,
        ),
      );

      // When: 記事一覧を取得する
      final items = await ArticlesApiClient(
        mock,
        baseUrl: baseUrl,
      ).fetchArticles();

      // Then: 空リストが返る
      expect(items, isEmpty);
    });

    // T21
    test(
      'should throw ApiHttpStatusException(500) when status is 500',
      () async {
        // Given: 500 を返す MockClient
        final mock = MockClient((_) async => http.Response('', 500));

        // When: 記事一覧を取得する
        final future = ArticlesApiClient(
          mock,
          baseUrl: baseUrl,
        ).fetchArticles();

        // Then: statusCode == 500 の ApiHttpStatusException が投げられる
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

    // T22
    test('should throw ApiConnectionException when connection fails', () async {
      // Given: ClientException を投げる MockClient
      final mock = MockClient(
        (_) async => throw http.ClientException('connection refused'),
      );

      // When: 記事一覧を取得する
      final future = ArticlesApiClient(mock, baseUrl: baseUrl).fetchArticles();

      // Then: ApiConnectionException が投げられる
      await expectLater(future, throwsA(isA<ApiConnectionException>()));
    });

    // T23
    test('should throw ApiTimeoutException when request times out', () async {
      // Given: 完了しないレスポンスを返す MockClient と 10ms のタイムアウト
      final mock = MockClient((_) => Completer<http.Response>().future);
      final client = ArticlesApiClient(
        mock,
        baseUrl: baseUrl,
        timeout: const Duration(milliseconds: 10),
      );

      // When: 記事一覧を取得する
      final future = client.fetchArticles();

      // Then: ApiTimeoutException が投げられる
      await expectLater(future, throwsA(isA<ApiTimeoutException>()));
    });

    // T24
    test(
      'should throw ApiFormatException when body is not JSON or items is missing/non-list',
      () async {
        // Given: 不正 JSON、items が非配列、items 欠損の MockClient
        final notJsonMock = MockClient(
          (_) async => http.Response('not json', 200),
        );
        final nonListItemsMock = MockClient(
          (_) async => http.Response('{"items": "invalid"}', 200),
        );
        final missingItemsMock = MockClient(
          (_) async => http.Response('{"limit": 100}', 200),
        );

        // When / Then: いずれも ApiFormatException が投げられる
        await expectLater(
          ArticlesApiClient(notJsonMock, baseUrl: baseUrl).fetchArticles(),
          throwsA(isA<ApiFormatException>()),
        );
        await expectLater(
          ArticlesApiClient(nonListItemsMock, baseUrl: baseUrl).fetchArticles(),
          throwsA(isA<ApiFormatException>()),
        );
        await expectLater(
          ArticlesApiClient(missingItemsMock, baseUrl: baseUrl).fetchArticles(),
          throwsA(isA<ApiFormatException>()),
        );
      },
    );
  });

  group('ArticlesApiClient.updateArticleRead', () {
    http.Response jsonResponse(Object body, [int statusCode = 200]) =>
        http.Response.bytes(
          utf8.encode(jsonEncode(body)),
          statusCode,
          headers: {'content-type': 'application/json'},
        );

    // T25
    test(
      'should send PATCH {baseUrl}/articles/{id} with JSON body and return updated ArticleItem',
      () async {
        // Given: 200 で isRead: true に更新された ArticleItem JSON を返す MockClient
        final requests = <http.Request>[];
        final updatedJson = <String, dynamic>{
          'id': 'a-1',
          'feedId': 'f-1',
          'isRead': true,
          'article': rssArticleA.toJson(),
        };
        final mock = MockClient((request) async {
          requests.add(request);
          return jsonResponse(updatedJson);
        });

        // When: updateArticleRead('a-1', isRead: true) を呼ぶ
        final item = await ArticlesApiClient(
          mock,
          baseUrl: baseUrl,
        ).updateArticleRead('a-1', isRead: true);

        // Then: PATCH リクエストが送られ、更新後の ArticleItem が返る
        expect(requests, hasLength(1));
        expect(requests.single.method, equals('PATCH'));
        expect(
          requests.single.url,
          equals(Uri.parse('http://localhost:8080/articles/a-1')),
        );
        expect(
          requests.single.headers['content-type'],
          contains('application/json'),
        );
        expect(requests.single.body, equals('{"isRead":true}'));
        expect(item.id, equals('a-1'));
        expect(item.isRead, isTrue);
      },
    );

    // T26
    test('should URL-encode path segment when id contains slash', () async {
      // Given: 200 を返す MockClient とリクエスト記録
      final requests = <http.Request>[];
      final updatedJson = <String, dynamic>{
        'id': 'id/with/slash',
        'feedId': 'f-1',
        'isRead': false,
        'article': rssArticleA.toJson(),
      };
      final mock = MockClient((request) async {
        requests.add(request);
        return jsonResponse(updatedJson);
      });

      // When: スラッシュを含む ID で更新する
      await ArticlesApiClient(
        mock,
        baseUrl: baseUrl,
      ).updateArticleRead('id/with/slash', isRead: false);

      // Then: パスセグメントが URL エンコードされて送信される
      expect(requests.single.url.path, equals('/articles/id%2Fwith%2Fslash'));
    });

    // T27
    test(
      'should throw ApiHttpStatusException(404) when status is 404',
      () async {
        // Given: 404 を返す MockClient
        final mock = MockClient((_) async => http.Response('', 404));

        // When: 存在しない ID で更新する
        final future = ArticlesApiClient(
          mock,
          baseUrl: baseUrl,
        ).updateArticleRead('missing', isRead: true);

        // Then: statusCode == 404 の ApiHttpStatusException が投げられる
        await expectLater(
          future,
          throwsA(
            isA<ApiHttpStatusException>().having(
              (e) => e.statusCode,
              'statusCode',
              404,
            ),
          ),
        );
      },
    );

    // T28
    test('should throw ApiConnectionException when connection fails', () async {
      // Given: ClientException を投げる MockClient
      final mock = MockClient(
        (_) async => throw http.ClientException('connection refused'),
      );

      // When: updateArticleRead を呼ぶ
      final future = ArticlesApiClient(
        mock,
        baseUrl: baseUrl,
      ).updateArticleRead('a-1', isRead: true);

      // Then: ApiConnectionException が投げられる
      await expectLater(future, throwsA(isA<ApiConnectionException>()));
    });

    // T29
    test('should throw ApiTimeoutException when request times out', () async {
      // Given: 完了しないレスポンスを返す MockClient と 10ms のタイムアウト
      final mock = MockClient((_) => Completer<http.Response>().future);
      final client = ArticlesApiClient(
        mock,
        baseUrl: baseUrl,
        timeout: const Duration(milliseconds: 10),
      );

      // When: updateArticleRead を呼ぶ
      final future = client.updateArticleRead('a-1', isRead: true);

      // Then: ApiTimeoutException が投げられる
      await expectLater(future, throwsA(isA<ApiTimeoutException>()));
    });

    // T30
    test(
      'should throw ApiFormatException when body is not JSON or schema mismatches',
      () async {
        // Given: 不正 JSON とスキーマ不一致 JSON の MockClient
        final notJsonMock = MockClient(
          (_) async => http.Response('not json', 200),
        );
        final invalidShapeMock = MockClient(
          (_) async => http.Response('{"id": 123}', 200),
        );

        // When / Then: どちらも ApiFormatException が投げられる
        await expectLater(
          ArticlesApiClient(
            notJsonMock,
            baseUrl: baseUrl,
          ).updateArticleRead('a-1', isRead: true),
          throwsA(isA<ApiFormatException>()),
        );
        await expectLater(
          ArticlesApiClient(
            invalidShapeMock,
            baseUrl: baseUrl,
          ).updateArticleRead('a-1', isRead: true),
          throwsA(isA<ApiFormatException>()),
        );
      },
    );
  });
}
