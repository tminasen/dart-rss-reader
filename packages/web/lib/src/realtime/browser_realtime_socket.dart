import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'realtime_socket.dart';

/// ブラウザの `WebSocket` を [RealtimeSocket] として使えるように包む。
///
/// `dart:js_interop` に依存するため、VM 上のテストでは動かせない。
class BrowserRealtimeSocket implements RealtimeSocket {
  BrowserRealtimeSocket(Uri uri) : _socket = web.WebSocket(uri.toString()) {
    _socket.onopen = ((web.Event _) {
      if (!_opened.isCompleted) _opened.complete();
    }).toJS;
    _socket.onerror = ((web.Event _) {
      _failOpening();
    }).toJS;
    _socket.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      if (data.isA<JSString>()) _messages.add((data as JSString).toDart);
    }).toJS;
    _socket.onclose = ((web.CloseEvent _) {
      _failOpening();
      _messages.close();
    }).toJS;
  }

  final web.WebSocket _socket;
  final Completer<void> _opened = Completer<void>();
  final StreamController<String> _messages = StreamController<String>();

  @override
  Future<void> get opened => _opened.future;

  @override
  Stream<String> get messages => _messages.stream;

  @override
  void close() => _socket.close();

  /// 接続が開く前に失敗・切断された場合に [opened] をエラーで完了する。
  void _failOpening() {
    if (!_opened.isCompleted) {
      _opened.completeError(StateError('WebSocket connection failed'));
    }
  }
}
