/// 新着配信の WebSocket 接続。ブラウザ実装をテストで差し替えるための境界。
abstract interface class RealtimeSocket {
  /// 接続が開くと完了する。接続に失敗したらエラーで完了する。
  Future<void> get opened;

  /// 受信したテキストメッセージ。切断されると done になる。
  Stream<String> get messages;

  void close();
}

/// 呼ぶたびに新しい接続を開始する。
typedef RealtimeSocketConnector = RealtimeSocket Function();
