import 'dart:convert';

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

const noTitleXml =
    '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>'
    '<title>Example Feed</title><link>https://example.com</link>'
    '<description>desc</description>'
    '<item><link>https://example.com/1</link></item>'
    '</channel></rss>';

const lastModifiedValue = 'Mon, 16 Nov 2026 12:00:00 GMT';

final feedUrl = Uri.parse('https://example.com/feed.xml');
final defaultFeedUrl = Uri.parse('https://tminasen.dev/rss/feed.xml');

http.Response rssResponse(
  String body, {
  int status = 200,
  Map<String, String> headers = const {},
}) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {'content-type': 'application/rss+xml', ...headers},
);

void main() {
  late List<http.Request> requests;
  late StringBuffer out;
  late StringBuffer err;

  setUp(() {
    requests = [];
    out = StringBuffer();
    err = StringBuffer();
  });

  FeedClient clientReturning(http.Response Function() response) => FeedClient(
    MockClient((request) async {
      requests.add(request);
      return response();
    }),
  );

  group('runFetchFeedCommand', () {
    test(
      'should print article titles one per line when fetch succeeds',
      () async {
        // Given: RSS を返すクライアント
        final client = clientReturning(() => rssResponse(rssXml));

        // When: URL を指定して実行する
        final code = await runFetchFeedCommand(
          ['https://example.com/feed.xml'],
          client: client,
          out: out,
          err: err,
        );

        // Then: 終了コード 0 でタイトルが1行ずつ表示される
        expect(code, equals(0));
        expect(out.toString(), equals('- First post\n- Second post\n'));
      },
    );

    test('should print (no title) when article has no title', () async {
      // Given: タイトルなしの記事を返すクライアント
      final client = clientReturning(() => rssResponse(noTitleXml));

      // When: 引数なしで実行する
      final code = await runFetchFeedCommand(
        [],
        client: client,
        out: out,
        err: err,
      );

      // Then: (no title) と表示される
      expect(code, equals(0));
      expect(out.toString(), equals('- (no title)\n'));
    });

    test('should fetch default feed when url is omitted', () async {
      // Given: リクエストを記録するクライアント
      final client = clientReturning(() => rssResponse(rssXml));

      // When: 引数なしで実行する
      await runFetchFeedCommand([], client: client, out: out, err: err);

      // Then: 既定のフィード URL へリクエストされる
      expect(requests.single.url, equals(defaultFeedUrl));
    });

    test('should fetch given url when url is specified', () async {
      // Given: リクエストを記録するクライアント
      final client = clientReturning(() => rssResponse(rssXml));

      // When: URL を指定して実行する
      await runFetchFeedCommand(
        ['https://example.com/feed.xml'],
        client: client,
        out: out,
        err: err,
      );

      // Then: 指定した URL へリクエストされる
      expect(requests.single.url, equals(feedUrl));
    });

    test('should print etag and last-modified before titles', () async {
      // Given: ETag / Last-Modified 付きで返すクライアント
      final client = clientReturning(
        () => rssResponse(
          rssXml,
          headers: {'etag': '"v2"', 'last-modified': lastModifiedValue},
        ),
      );

      // When: 引数なしで実行する
      final code = await runFetchFeedCommand(
        [],
        client: client,
        out: out,
        err: err,
      );

      // Then: ヘッダー値がタイトルの前に表示される
      expect(code, equals(0));
      expect(
        out.toString(),
        equals(
          'ETag: "v2"\n'
          'Last-Modified: Mon, 16 Nov 2026 12:00:00 GMT\n'
          '- First post\n'
          '- Second post\n',
        ),
      );
    });

    test('should send If-None-Match when --etag is given', () async {
      // Given: リクエストを記録するクライアント
      final client = clientReturning(() => rssResponse(rssXml));

      // When: --etag を指定して実行する
      await runFetchFeedCommand(
        ['--etag', '"v1"'],
        client: client,
        out: out,
        err: err,
      );

      // Then: If-None-Match ヘッダーが送られる
      expect(requests.single.headers['If-None-Match'], equals('"v1"'));
    });

    test(
      'should send If-Modified-Since when --last-modified is given',
      () async {
        // Given: リクエストを記録するクライアント
        final client = clientReturning(() => rssResponse(rssXml));

        // When: --last-modified を指定して実行する
        await runFetchFeedCommand(
          ['--last-modified', lastModifiedValue],
          client: client,
          out: out,
          err: err,
        );

        // Then: If-Modified-Since ヘッダーが送られる
        expect(
          requests.single.headers['If-Modified-Since'],
          equals('Mon, 16 Nov 2026 12:00:00 GMT'),
        );
      },
    );

    test('should print Not modified (304) when response is 304', () async {
      // Given: 304 を返すクライアント
      final client = clientReturning(() => http.Response('', 304));

      // When: --etag を指定して実行する
      final code = await runFetchFeedCommand(
        ['--etag', '"v1"'],
        client: client,
        out: out,
        err: err,
      );

      // Then: 終了コード 0 で Not modified (304) が表示される
      expect(code, equals(0));
      expect(out.toString(), equals('Not modified (304)\n'));
    });

    test(
      'should return 1 and print error to stderr when fetch fails',
      () async {
        // Given: 404 を返すクライアント
        final client = clientReturning(() => http.Response('Not Found', 404));

        // When: 引数なしで実行する
        final code = await runFetchFeedCommand(
          [],
          client: client,
          out: out,
          err: err,
        );

        // Then: 終了コード 1、標準エラーにメッセージ、標準出力は空
        expect(code, equals(1));
        expect(err.toString(), isNotEmpty);
        expect(out.toString(), isEmpty);
      },
    );

    test(
      'should return 64 and not send request when --etag has no value',
      () async {
        // Given: リクエストを記録するクライアント
        final client = clientReturning(() => rssResponse(rssXml));

        // When: 値のない --etag で実行する
        final code = await runFetchFeedCommand(
          ['--etag'],
          client: client,
          out: out,
          err: err,
        );

        // Then: 終了コード 64、標準エラーに使い方、リクエストは送られない
        expect(code, equals(64));
        expect(err.toString(), isNotEmpty);
        expect(requests, isEmpty);
      },
    );

    test(
      'should return 64 and not send request when an unknown option is given',
      () async {
        // Given: リクエストを記録するクライアント
        final client = clientReturning(() => rssResponse(rssXml));

        // When: 未知のオプションで実行する
        final code = await runFetchFeedCommand(
          ['--foo'],
          client: client,
          out: out,
          err: err,
        );

        // Then: 終了コード 64、標準エラーに使い方、リクエストは送られない
        expect(code, equals(64));
        expect(err.toString(), isNotEmpty);
        expect(requests, isEmpty);
      },
    );

    test(
      'should return 64 and not send request when two urls are given',
      () async {
        // Given: リクエストを記録するクライアント
        final client = clientReturning(() => rssResponse(rssXml));

        // When: URL を2つ指定して実行する
        final code = await runFetchFeedCommand(
          ['https://example.com/a.xml', 'https://example.com/b.xml'],
          client: client,
          out: out,
          err: err,
        );

        // Then: 終了コード 64、標準エラーに使い方、リクエストは送られない
        expect(code, equals(64));
        expect(err.toString(), isNotEmpty);
        expect(requests, isEmpty);
      },
    );

    test(
      'should return 64 and not send request when url scheme is not http or https',
      () async {
        // Given: リクエストを記録するクライアント
        final client = clientReturning(() => rssResponse(rssXml));

        // When: ftp の URL で実行する
        final code = await runFetchFeedCommand(
          ['ftp://example.com/feed.xml'],
          client: client,
          out: out,
          err: err,
        );

        // Then: 終了コード 64、標準エラーに使い方、リクエストは送られない
        expect(code, equals(64));
        expect(err.toString(), isNotEmpty);
        expect(requests, isEmpty);
      },
    );

    test(
      'should return 64 and not send request when url has no host',
      () async {
        // Given: リクエストを記録するクライアント
        final client = clientReturning(() => rssResponse(rssXml));

        // When: ホストのない URL で実行する
        final code = await runFetchFeedCommand(
          ['https:'],
          client: client,
          out: out,
          err: err,
        );

        // Then: 終了コード 64、標準エラーに使い方、リクエストは送られない
        expect(code, equals(64));
        expect(err.toString(), isNotEmpty);
        expect(requests, isEmpty);
      },
    );
  });
}
