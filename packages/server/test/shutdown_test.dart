import 'dart:async';

import 'package:server/src/shutdown.dart';
import 'package:test/test.dart';

void main() {
  group('waitForShutdown', () {
    // T22
    test(
      'should close all resources in order and cancel signal subscription when signal arrives',
      () async {
        // Given: 呼び出し順を記録する5つのクローズ関数とシグナル用 StreamController
        final events = <String>[];
        final signalController = StreamController<void>();
        addTearDown(() {
          signalController.close();
        });

        // When: waitForShutdown を開始してシグナルを1回送る
        final future = waitForShutdown(
          signals: signalController.stream,
          closeServer: () async => events.add('server'),
          closeHttpClient: () => events.add('httpClient'),
          stopScheduler: () async => events.add('scheduler'),
          closeCrawler: () async => events.add('crawler'),
          closeRepositories: () => events.add('repositories'),
        );
        signalController.add(null);
        await future;

        // Then: 指定順序で1回ずつクローズされ、シグナル購読が解除される
        expect(
          events,
          equals([
            'server',
            'httpClient',
            'scheduler',
            'crawler',
            'repositories',
          ]),
        );
        expect(signalController.hasListener, isFalse);
      },
    );

    // T23
    test(
      'should continue remaining closes and report error to onError when a close step throws',
      () async {
        // Given: closeServer が例外を投げ、他4関数は呼び出し順を記録する構成
        final events = <String>[];
        final errors = <Object>[];
        final signalController = StreamController<void>();
        addTearDown(() {
          signalController.close();
        });

        // When: waitForShutdown を開始してシグナルを送る
        final future = waitForShutdown(
          signals: signalController.stream,
          closeServer: () async => throw StateError('close failed'),
          closeHttpClient: () => events.add('httpClient'),
          stopScheduler: () async => events.add('scheduler'),
          closeCrawler: () async => events.add('crawler'),
          closeRepositories: () => events.add('repositories'),
          onError: (error, _) => errors.add(error),
        );
        signalController.add(null);
        await future;

        // Then: 残りのクローズ処理がすべて実行され、errors に StateError が1件記録される
        expect(
          events,
          equals(['httpClient', 'scheduler', 'crawler', 'repositories']),
        );
        expect(errors, hasLength(1));
        expect(errors.single, isA<StateError>());
      },
    );

    // T24
    test(
      'should execute close sequence only once when multiple signals arrive during shutdown',
      () async {
        // Given: closeServer が gate で待機する5つのクローズ関数
        final events = <String>[];
        final gate = Completer<void>();
        final signalController = StreamController<void>();
        addTearDown(() {
          signalController.close();
        });

        final future = waitForShutdown(
          signals: signalController.stream,
          closeServer: () {
            events.add('server');
            return gate.future;
          },
          closeHttpClient: () => events.add('httpClient'),
          stopScheduler: () async => events.add('scheduler'),
          closeCrawler: () async => events.add('crawler'),
          closeRepositories: () => events.add('repositories'),
        );

        // When: シグナルを2回連続で送り、その後 gate を完了する
        signalController.add(null);
        signalController.add(null);
        await pumpEventQueue();
        gate.complete();
        await future;

        // Then: クローズ処理は指定順序で1回だけ実行される
        expect(
          events,
          equals([
            'server',
            'httpClient',
            'scheduler',
            'crawler',
            'repositories',
          ]),
        );
      },
    );
  });
}
