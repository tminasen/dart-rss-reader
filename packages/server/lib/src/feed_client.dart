import 'dart:async';
import 'dart:convert';
import 'dart:io' show TlsException;

import 'package:http/http.dart' as http;
import 'package:shared/shared.dart';

import 'feed_fetch_exception.dart';

/// [FeedClient.fetch] の結果。
sealed class FeedFetchResult {
  const FeedFetchResult();
}

/// フィードが取得できた。
final class FeedUpdated extends FeedFetchResult {
  const FeedUpdated({
    required this.feed,
    required this.articles,
    this.etag,
    this.lastModified,
  });

  final RssFeed feed;
  final List<RssArticle> articles;
  final String? etag;
  final String? lastModified;
}

/// 304 Not Modified（更新なし）。
final class FeedNotModified extends FeedFetchResult {
  const FeedNotModified();
}

/// フィードを HTTP で取得するクライアント。
final class FeedClient {
  FeedClient(this._httpClient, {this.timeout = const Duration(seconds: 10)});

  final http.Client _httpClient;
  final Duration timeout;

  Future<FeedFetchResult> fetch(
    Uri url, {
    String? etag,
    String? lastModified,
  }) async {
    final http.Response response;
    try {
      response = await _httpClient
          .get(
            url,
            headers: {
              'If-None-Match': ?etag,
              'If-Modified-Since': ?lastModified,
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw FeedTimeoutException('Request timed out after $timeout: $url');
    } on http.ClientException catch (e) {
      throw FeedConnectionException('Failed to connect to $url: ${e.message}');
    } on TlsException catch (e) {
      throw FeedConnectionException(
        'TLS handshake with $url failed: ${e.message}',
      );
    }
    if (response.statusCode == 304) return const FeedNotModified();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FeedHttpStatusException(
        response.statusCode,
        'Unexpected status ${response.statusCode} from $url',
      );
    }
    final RssParseResult parsed;
    try {
      parsed = parseRss(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw FeedParseException(
        'Response body is not valid UTF-8: ${e.message}',
      );
    } on RssParseException catch (e) {
      throw FeedParseException('Failed to parse feed from $url: ${e.message}');
    }
    return FeedUpdated(
      feed: parsed.feed,
      articles: parsed.articles,
      etag: response.headers['etag'],
      lastModified: response.headers['last-modified'],
    );
  }
}
