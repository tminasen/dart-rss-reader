const defaultFeedUrl = 'https://tminasen.dev/rss/feed.xml';
const defaultCrawlInterval = Duration(minutes: 30);

/// どのフィードを、どの間隔で巡回するか。
final class CrawlConfig {
  const CrawlConfig({required this.feedUrl, required this.interval});

  /// 環境変数 `FEED_URL`（未指定なら [defaultFeedUrl]）と
  /// `CRAWL_INTERVAL_MINUTES`（正の整数・分。未指定なら [defaultCrawlInterval]）から作る。
  /// 空文字は未指定として扱う。`FEED_URL` が http/https でない、ホストがない、
  /// または `CRAWL_INTERVAL_MINUTES` が正の整数でなければ [ArgumentError] を投げる。
  factory CrawlConfig.fromEnvironment(Map<String, String> environment) {
    final feedUrl = _nonEmpty(environment['FEED_URL']) ?? defaultFeedUrl;
    final uri = Uri.tryParse(feedUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw ArgumentError.value(
        feedUrl,
        'FEED_URL',
        'must be an http(s) URL with a host',
      );
    }
    final minutes = _nonEmpty(environment['CRAWL_INTERVAL_MINUTES']);
    return CrawlConfig(
      feedUrl: feedUrl,
      interval: minutes == null
          ? defaultCrawlInterval
          : Duration(minutes: _parsePositiveInt(minutes)),
    );
  }

  final String feedUrl;
  final Duration interval;
}

int _parsePositiveInt(String value) {
  final n = int.tryParse(value);
  if (n == null || n < 1) {
    throw ArgumentError.value(
      value,
      'CRAWL_INTERVAL_MINUTES',
      'must be a positive integer',
    );
  }
  return n;
}

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;
