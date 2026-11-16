import 'feed_client.dart';
import 'feed_fetch_exception.dart';

final _defaultFeedUrl = Uri.parse('https://tminasen.dev/rss/feed.xml');

/// フィード取得 CLI の本体。終了コードを返す。
Future<int> runFetchFeedCommand(
  List<String> args, {
  required FeedClient client,
  required StringSink out,
  required StringSink err,
}) async {
  Uri? url;
  String? etag;
  String? lastModified;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--etag':
        if (i + 1 >= args.length) {
          return _usageError(err, '$arg requires a value');
        }
        etag = args[++i];
      case '--last-modified':
        if (i + 1 >= args.length) {
          return _usageError(err, '$arg requires a value');
        }
        lastModified = args[++i];
      case _ when arg.startsWith('--'):
        return _usageError(err, 'Unknown option: $arg');
      default:
        if (url != null) return _usageError(err, 'Too many arguments');
        final parsed = Uri.tryParse(arg);
        if (parsed == null ||
            !{'http', 'https'}.contains(parsed.scheme) ||
            parsed.host.isEmpty) {
          return _usageError(
            err,
            'URL must be http or https with a host: $arg',
          );
        }
        url = parsed;
    }
  }
  url ??= _defaultFeedUrl;

  final FeedFetchResult result;
  try {
    result = await client.fetch(url, etag: etag, lastModified: lastModified);
  } on FeedFetchException catch (e) {
    err.writeln('Error: ${e.message}');
    return 1;
  }

  switch (result) {
    case FeedUpdated():
      if (result.etag case final etag?) out.writeln('ETag: $etag');
      if (result.lastModified case final lastModified?) {
        out.writeln('Last-Modified: $lastModified');
      }
      for (final article in result.articles) {
        out.writeln('- ${article.title ?? '(no title)'}');
      }
    case FeedNotModified():
      out.writeln('Not modified (304)');
  }
  return 0;
}

const _usage =
    'Usage: fetch_feed [--etag <value>] [--last-modified <value>] [<url>]';

/// 引数エラーを標準エラーへ出し、EX_USAGE（64）を返す。
int _usageError(StringSink err, String message) {
  err
    ..writeln('Error: $message')
    ..writeln(_usage);
  return 64;
}
