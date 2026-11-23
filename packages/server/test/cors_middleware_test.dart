import 'package:server/server.dart';
import 'package:server/src/repository/in_memory_article_repository.dart';
import 'package:server/src/repository/in_memory_subscription_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'repository/fixtures.dart';

void noopLogger(String message, bool isError) {}

const allowedOrigin = 'http://localhost:8081';
const otherOrigin = 'http://evil.example';

void main() {
  group('CORS middleware', () {
    final feedsUri = Uri.parse('http://localhost/feeds');
    final articleUri = Uri.parse('http://localhost/articles/1');
    late InMemorySubscriptionRepository subRepo;
    late InMemoryArticleRepository articleRepo;
    late Handler handler;

    setUp(() {
      subRepo = InMemorySubscriptionRepository();
      articleRepo = InMemoryArticleRepository();
      handler = buildHandler(
        subscriptionRepository: subRepo,
        articleRepository: articleRepo,
        allowedOrigins: {allowedOrigin},
        logger: noopLogger,
      );
    });

    test(
      'should add CORS headers when GET comes from an allowed origin',
      () async {
        // Given: 購読が1件あり、許可オリジンからのリクエスト
        await subRepo.add(feedUrlA);

        // When: GET /feeds を処理する
        final response = await handler(
          Request('GET', feedsUri, headers: {'origin': allowedOrigin}),
        );

        // Then: 200 で、許可オリジンと vary: Origin が付く
        expect(response.statusCode, equals(200));
        expect(
          response.headers['access-control-allow-origin'],
          equals('http://localhost:8081'),
        );
        expect(response.headers['vary'], equals('Origin'));
      },
    );

    test(
      'should add CORS headers when PATCH comes from an allowed origin',
      () async {
        // Given: 記事 '1' が登録されており、許可オリジンからの PATCH リクエスト
        await articleRepo.addAll('1', [rss(1)]);

        // When: PATCH /articles/1 を処理する
        final response = await handler(
          Request(
            'PATCH',
            articleUri,
            headers: {
              'origin': allowedOrigin,
              'content-type': 'application/json',
            },
            body: '{"isRead":true}',
          ),
        );

        // Then: 200 で、access-control-allow-origin と vary: Origin が付く
        expect(response.statusCode, equals(200));
        expect(
          response.headers['access-control-allow-origin'],
          equals(allowedOrigin),
        );
        expect(response.headers['vary'], equals('Origin'));
      },
    );

    test(
      'should respond 204 with GET, PATCH and Content-Type when preflight comes from an allowed origin',
      () async {
        // Given: 許可オリジンからの PATCH + Content-Type プリフライト

        // When: OPTIONS /articles/1 を処理する
        final response = await handler(
          Request(
            'OPTIONS',
            articleUri,
            headers: {
              'origin': allowedOrigin,
              'access-control-request-method': 'PATCH',
              'access-control-request-headers': 'content-type',
            },
          ),
        );

        // Then: 204 で、許可オリジン・GET, PATCH・Content-Type・vary: Origin が返る
        expect(response.statusCode, equals(204));
        expect(
          response.headers['access-control-allow-origin'],
          equals(allowedOrigin),
        );
        expect(
          response.headers['access-control-allow-methods'],
          equals('GET, PATCH'),
        );
        expect(
          response.headers['access-control-allow-headers'],
          equals('Content-Type'),
        );
        expect(response.headers['vary'], equals('Origin'));
      },
    );

    test(
      'should not add CORS headers when GET comes from another origin',
      () async {
        // Given: 購読が1件あり、許可外オリジンからのリクエスト
        await subRepo.add(feedUrlA);

        // When: GET /feeds を処理する
        final response = await handler(
          Request('GET', feedsUri, headers: {'origin': otherOrigin}),
        );

        // Then: 200 で、CORS ヘッダは付かない
        expect(response.statusCode, equals(200));
        expect(
          response.headers.containsKey('access-control-allow-origin'),
          isFalse,
        );
      },
    );

    test('should not add CORS headers when GET has no Origin header', () async {
      // Given: 購読が1件あり、Origin ヘッダの無いリクエスト
      await subRepo.add(feedUrlA);

      // When: GET /feeds を処理する
      final response = await handler(Request('GET', feedsUri));

      // Then: 200 で、CORS ヘッダは付かない
      expect(response.statusCode, equals(200));
      expect(
        response.headers.containsKey('access-control-allow-origin'),
        isFalse,
      );
    });

    test(
      'should respond 403 when preflight comes from another origin',
      () async {
        // Given: 許可外オリジンからのプリフライト

        // When: OPTIONS /feeds を処理する
        final response = await handler(
          Request(
            'OPTIONS',
            feedsUri,
            headers: {
              'origin': otherOrigin,
              'access-control-request-method': 'GET',
            },
          ),
        );

        // Then: 403 で、CORS ヘッダは付かない
        expect(response.statusCode, equals(403));
        expect(
          response.headers.containsKey('access-control-allow-origin'),
          isFalse,
        );
      },
    );
  });
}
