import 'package:server/src/crawl_config.dart';
import 'package:test/test.dart';

import 'repository/fixtures.dart';

void main() {
  group('CrawlConfig.fromEnvironment', () {
    test('should use defaults when nothing is set', () {
      // Given: 何も指定していない環境変数
      final environment = <String, String>{};

      // When: 設定を作る
      final config = CrawlConfig.fromEnvironment(environment);

      // Then: 既定のURLと30分になる
      expect(config.feedUrl, equals('https://tminasen.dev/rss/feed.xml'));
      expect(config.interval, equals(const Duration(minutes: 30)));
    });

    test('should use the given URL when FEED_URL is set', () {
      // Given: FEED_URL を指定した環境変数
      final environment = {'FEED_URL': feedUrlB};

      // When: 設定を作る
      final config = CrawlConfig.fromEnvironment(environment);

      // Then: 指定したURLになる
      expect(config.feedUrl, equals(feedUrlB));
    });

    test('should treat empty values as unset when they are empty strings', () {
      // Given: 空文字の環境変数
      final environment = {'FEED_URL': '', 'CRAWL_INTERVAL_MINUTES': ''};

      // When: 設定を作る
      final config = CrawlConfig.fromEnvironment(environment);

      // Then: 既定値になる
      expect(config.feedUrl, equals('https://tminasen.dev/rss/feed.xml'));
      expect(config.interval, equals(const Duration(minutes: 30)));
    });

    test('should throw ArgumentError when FEED_URL scheme is not http(s)', () {
      // Given: ftp スキームのURL
      final environment = {'FEED_URL': 'ftp://example.com/feed.xml'};

      // When / Then: 拒否される
      expect(
        () => CrawlConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    test('should throw ArgumentError when FEED_URL has no host', () {
      // Given: ホストのないURL
      final environment = {'FEED_URL': 'https:///feed.xml'};

      // When / Then: 拒否される
      expect(
        () => CrawlConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    test('should use the given minutes when CRAWL_INTERVAL_MINUTES is set', () {
      // Given: 間隔を5分と指定した環境変数
      final environment = {'CRAWL_INTERVAL_MINUTES': '5'};

      // When: 設定を作る
      final config = CrawlConfig.fromEnvironment(environment);

      // Then: 5分になる
      expect(config.interval, equals(const Duration(minutes: 5)));
    });

    test('should throw ArgumentError when CRAWL_INTERVAL_MINUTES is not an '
        'integer', () {
      // Given: 整数でない間隔
      final environment = {'CRAWL_INTERVAL_MINUTES': 'abc'};

      // When / Then: 拒否される
      expect(
        () => CrawlConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    test('should throw ArgumentError when CRAWL_INTERVAL_MINUTES is 0', () {
      // Given: 0分の間隔
      final environment = {'CRAWL_INTERVAL_MINUTES': '0'};

      // When / Then: 拒否される
      expect(
        () => CrawlConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    test('should accept 1 minute when CRAWL_INTERVAL_MINUTES is 1', () {
      // Given: 1分の間隔
      final environment = {'CRAWL_INTERVAL_MINUTES': '1'};

      // When: 設定を作る
      final config = CrawlConfig.fromEnvironment(environment);

      // Then: 1分になる
      expect(config.interval, equals(const Duration(minutes: 1)));
    });
  });
}
