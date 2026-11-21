/// API の呼び出しに失敗したことを表す例外。
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 成功（2xx）以外の HTTP ステータスが返った。
final class ApiHttpStatusException extends ApiException {
  ApiHttpStatusException(this.statusCode)
    : super('Unexpected status $statusCode');

  final int statusCode;
}

/// サーバーへ接続できなかった。
final class ApiConnectionException extends ApiException {
  const ApiConnectionException(super.message);
}

/// 応答がタイムアウトした。
final class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message);
}

/// レスポンス本文を `FeedSummary` のリストとして読めなかった。
final class ApiFormatException extends ApiException {
  const ApiFormatException(super.message);
}
