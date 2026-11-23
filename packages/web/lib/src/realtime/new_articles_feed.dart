import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:shared/shared.dart';

import 'connection_status.dart';
import 'new_article_message.dart';
import 'realtime_socket.dart';

Future<void> _delay(Duration duration) => Future<void>.delayed(duration);

/// WebSocket から新着記事を受信して流し、接続状態を保持する。
class NewArticlesFeed {
  NewArticlesFeed({
    required RealtimeSocketConnector connect,
    Duration reconnectDelay = const Duration(seconds: 3),
    Future<void> Function(Duration) wait = _delay,
  }) : _connect = connect,
       _reconnectDelay = reconnectDelay,
       _wait = wait;

  final RealtimeSocketConnector _connect;
  final Duration _reconnectDelay;
  final Future<void> Function(Duration) _wait;

  final ValueNotifier<ConnectionStatus> _status = ValueNotifier(
    ConnectionStatus.reconnecting,
  );
  final StreamController<ArticleItem> _articles =
      StreamController<ArticleItem>.broadcast();

  /// 接続状態。初回の接続が開くまでは [ConnectionStatus.reconnecting]。
  ValueListenable<ConnectionStatus> get status => _status;

  /// 受信した新着記事。
  Stream<ArticleItem> get articles => _articles.stream;

  RealtimeSocket? _socket;
  bool _isDisposed = false;

  /// 接続を開始する。切断・失敗のたびに待ってから再接続し、[dispose] まで続ける。
  void start() {
    _run();
  }

  Future<void> _run() async {
    while (!_isDisposed) {
      final socket = _connect();
      _socket = socket;
      try {
        await socket.opened;
        if (_isDisposed) return;
        _status.value = ConnectionStatus.connected;
        await for (final message in socket.messages) {
          final item = parseNewArticleMessage(message);
          if (item != null) _articles.add(item);
        }
      } on Object {
        // 接続失敗・ストリームのエラーは切断と同じく再接続に進む。
      }
      if (_isDisposed) return;
      _status.value = ConnectionStatus.reconnecting;
      await _wait(_reconnectDelay);
    }
  }

  /// 開いているソケットを閉じ、再接続を止める。
  void dispose() {
    _isDisposed = true;
    _socket?.close();
    _articles.close();
  }
}
