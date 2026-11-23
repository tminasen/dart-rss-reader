import 'dart:async';
import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_app/src/realtime/connection_status.dart';
import 'package:web_app/src/realtime/new_articles_feed.dart';
import 'package:web_app/src/realtime/realtime_socket.dart';

final newRssArticle = RssArticle(
  title: '新着記事のタイトル',
  link: 'https://tminasen.dev/blog/new',
  pubDate: DateTime(2026, 11, 15),
  enclosure: null,
);

final newItem = ArticleItem(
  id: 'n-1',
  feedId: 'f-1',
  isRead: false,
  article: newRssArticle,
);

final newItemJson = jsonEncode(newItem.toJson());

class FakeRealtimeSocket implements RealtimeSocket {
  final Completer<void> _opened = Completer<void>();
  final StreamController<String> _messages = StreamController<String>();
  bool isClosed = false;

  @override
  Future<void> get opened => _opened.future;

  @override
  Stream<String> get messages => _messages.stream;

  @override
  void close() {
    isClosed = true;
  }

  void open() => _opened.complete();

  void fail() => _opened.completeError(Exception('connection failed'));

  void send(String message) => _messages.add(message);

  void disconnect() => _messages.close();

  void error() => _messages.addError(Exception('stream error'));
}

void main() {
  late List<FakeRealtimeSocket> sockets;
  late List<Duration> waits;
  late List<Completer<void>> waitCompleters;
  late NewArticlesFeed feed;

  RealtimeSocket fakeConnector() {
    final socket = FakeRealtimeSocket();
    sockets.add(socket);
    return socket;
  }

  Future<void> fakeWait(Duration duration) {
    waits.add(duration);
    final completer = Completer<void>();
    waitCompleters.add(completer);
    return completer.future;
  }

  setUp(() {
    sockets = [];
    waits = [];
    waitCompleters = [];
    feed = NewArticlesFeed(connect: fakeConnector, wait: fakeWait);
  });

  group('NewArticlesFeed', () {
    test('should be reconnecting before the socket opens', () async {
      // Given: fakeConnector, fakeWait

      // When: start する（sockets[0] はまだ開かない）
      feed.start();
      await pumpEventQueue();

      // Then: 未接続のまま、ソケットは1件だけ作られる
      expect(feed.status.value, equals(ConnectionStatus.reconnecting));
      expect(sockets.length, equals(1));
    });

    test('should become connected when the socket opens', () async {
      // Given: start 済みで sockets[0] はまだ開かない
      feed.start();
      await pumpEventQueue();

      // When: sockets[0] が開く
      sockets[0].open();
      await pumpEventQueue();

      // Then: 接続済みになる
      expect(feed.status.value, equals(ConnectionStatus.connected));
    });

    test('should emit received ArticleItem to articles', () async {
      // Given: 接続済みの sockets[0] と articles の購読
      final received = <ArticleItem>[];
      feed.articles.listen(received.add);
      feed.start();
      sockets[0].open();
      await pumpEventQueue();

      // When: ArticleItem の JSON を受信する
      sockets[0].send(newItemJson);
      await pumpEventQueue();

      // Then: articles に newItem が1件流れる
      expect(received, equals([newItem]));
    });

    test('should drop unreadable messages and keep the connection', () async {
      // Given: 接続済みの sockets[0] と articles の購読
      final received = <ArticleItem>[];
      feed.articles.listen(received.add);
      feed.start();
      sockets[0].open();
      await pumpEventQueue();

      // When: 読めないメッセージ、続けて ArticleItem の JSON を受信する
      sockets[0].send('not json');
      sockets[0].send(newItemJson);
      await pumpEventQueue();

      // Then: 流れたのは newItem のみで、接続は維持される
      expect(received, equals([newItem]));
      expect(feed.status.value, equals(ConnectionStatus.connected));
      expect(waits, isEmpty);
      expect(sockets[0].isClosed, isFalse);
    });

    test(
      'should wait 3 seconds while reconnecting when connection fails',
      () async {
        // Given: start 直後の sockets[0]
        feed.start();
        await pumpEventQueue();

        // When: 接続が失敗する
        sockets[0].fail();
        await pumpEventQueue();

        // Then: 未接続のまま3秒待つ
        expect(feed.status.value, equals(ConnectionStatus.reconnecting));
        expect(waits, equals([const Duration(seconds: 3)]));
      },
    );

    test(
      'should become reconnecting and wait when a connected socket is closed',
      () async {
        // Given: 接続済みの sockets[0]
        feed.start();
        sockets[0].open();
        await pumpEventQueue();
        expect(feed.status.value, equals(ConnectionStatus.connected));

        // When: 切断される
        sockets[0].disconnect();
        await pumpEventQueue();

        // Then: 未接続になり、3秒待つ
        expect(feed.status.value, equals(ConnectionStatus.reconnecting));
        expect(waits, equals([const Duration(seconds: 3)]));
      },
    );

    test('should treat a message stream error as a disconnect', () async {
      // Given: 接続済みの sockets[0]
      feed.start();
      sockets[0].open();
      await pumpEventQueue();

      // When: messages にエラーが流れる
      sockets[0].error();
      await pumpEventQueue();

      // Then: 未接続になり、3秒待つ
      expect(feed.status.value, equals(ConnectionStatus.reconnecting));
      expect(waits, equals([const Duration(seconds: 3)]));
    });

    test(
      'should reconnect after the wait and become connected again',
      () async {
        // Given: 切断されて待っている状態
        feed.start();
        sockets[0].open();
        await pumpEventQueue();
        sockets[0].disconnect();
        await pumpEventQueue();

        // When: 待ち終わり、sockets[1] が開く
        waitCompleters[0].complete();
        await pumpEventQueue();
        sockets[1].open();
        await pumpEventQueue();

        // Then: ソケットが2件になり、接続済みに戻る
        expect(sockets.length, equals(2));
        expect(feed.status.value, equals(ConnectionStatus.connected));
      },
    );

    test('should not reconnect when disposed while waiting', () async {
      // Given: 切断されて待っている状態
      feed.start();
      sockets[0].open();
      await pumpEventQueue();
      sockets[0].disconnect();
      await pumpEventQueue();

      // When: 破棄してから待ちが終わる
      feed.dispose();
      waitCompleters[0].complete();
      await pumpEventQueue();

      // Then: 再接続されない
      expect(sockets.length, equals(1));
    });

    test('should close the open socket when disposed', () async {
      // Given: 接続済みの sockets[0]
      feed.start();
      sockets[0].open();
      await pumpEventQueue();

      // When: 破棄する
      feed.dispose();

      // Then: ソケットが閉じられ、待ちは発生しない
      expect(sockets[0].isClosed, isTrue);
      expect(waits, isEmpty);
    });
  });
}
