/// フィード取得に失敗したことを表す例外。
sealed class FeedFetchException implements Exception {
  const FeedFetchException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 取得がタイムアウトした。
final class FeedTimeoutException extends FeedFetchException {
  const FeedTimeoutException(super.message);
}

/// サーバーへ接続できなかった。
final class FeedConnectionException extends FeedFetchException {
  const FeedConnectionException(super.message);
}

/// 成功（2xx）・304 以外の HTTP ステータスが返った。
final class FeedHttpStatusException extends FeedFetchException {
  const FeedHttpStatusException(this.statusCode, super.message);

  final int statusCode;
}

/// レスポンス本文をフィードとして読めなかった。
final class FeedParseException extends FeedFetchException {
  const FeedParseException(super.message);
}
