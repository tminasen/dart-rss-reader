import 'dart:async';

import 'package:server/src/crawl_scheduler.dart';
import 'package:test/test.dart';

/// 時間を進めずに、テストから [fire] で周期を発火させる Timer。
class FakeTimer implements Timer {
  FakeTimer(this.duration, this.callback);

  final Duration duration;
  final void Function(Timer) callback;
  bool _active = true;

  void fire() => callback(this);

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

void main() {
  const interval = Duration(minutes: 30);

  late int count;
  late List<FakeTimer> timers;
  late List<Object> errors;
  late Future<void> Function() task;

  CrawlScheduler newScheduler() => CrawlScheduler(
    task: () => task(),
    interval: interval,
    createTimer: (duration, callback) {
      final timer = FakeTimer(duration, callback);
      timers.add(timer);
      return timer;
    },
    onError: (error, _) => errors.add(error),
  );

  setUp(() {
    count = 0;
    timers = [];
    errors = [];
    task = () async {
      count++;
    };
  });

  group('CrawlScheduler', () {
    test('should run the task once immediately when started', () {
      // Given: 呼び出し回数を数えるタスク
      final scheduler = newScheduler();

      // When: 開始する
      scheduler.start();

      // Then: タイマーが発火する前に1回実行されている
      expect(count, equals(1));
    });

    test('should create a timer with the configured interval when started', () {
      // Given: 30分間隔のスケジューラー
      final scheduler = newScheduler();

      // When: 開始する
      scheduler.start();

      // Then: 30分のタイマーが1つだけ作られる
      expect(timers, hasLength(1));
      expect(timers.single.duration, equals(interval));
    });

    test('should run the task on every tick when the timer fires', () async {
      // Given: 開始済みのスケジューラー
      final scheduler = newScheduler()..start();
      await pumpEventQueue();

      // When: 周期が2回来る
      timers.single.fire();
      await pumpEventQueue();
      timers.single.fire();
      await pumpEventQueue();

      // Then: 開始時の1回と合わせて3回実行されている
      expect(count, equals(3));
      scheduler.stop();
    });

    test(
      'should skip a tick when the previous run is still in progress',
      () async {
        // Given: 1回目が終わらないタスク
        final firstRun = Completer<void>();
        task = () {
          count++;
          return count == 1 ? firstRun.future : Future.value();
        };
        final scheduler = newScheduler()..start();

        // When: 実行中に周期が来る
        timers.single.fire();
        await pumpEventQueue();
        final countWhileRunning = count;
        firstRun.complete();
        await pumpEventQueue();
        timers.single.fire();
        await pumpEventQueue();

        // Then: 実行中の周期はスキップされ、終了後の周期は実行される
        expect(countWhileRunning, equals(1));
        expect(count, equals(2));
        scheduler.stop();
      },
    );

    test(
      'should report the error and run again when the task throws',
      () async {
        // Given: 1回目だけ例外を投げるタスク
        task = () async {
          count++;
          if (count == 1) throw StateError('boom');
        };
        final scheduler = newScheduler();

        // When: 開始して次の周期を迎える
        scheduler.start();
        await pumpEventQueue();
        timers.single.fire();
        await pumpEventQueue();

        // Then: エラーが通知され、次の周期でも実行される
        expect(errors, hasLength(1));
        expect(errors.single, isA<StateError>());
        expect(count, equals(2));
        scheduler.stop();
      },
    );

    test('should cancel the timer when stopped', () {
      // Given: 開始済みのスケジューラー
      final scheduler = newScheduler()..start();

      // When: 停止する
      scheduler.stop();

      // Then: タイマーが止まる
      expect(timers.single.isActive, isFalse);
    });

    // T19
    test(
      'should cancel timer immediately and wait for in-flight task when stopped',
      () async {
        // Given: 完了待ちの巡回タスクで開始済みのスケジューラー
        final firstRun = Completer<void>();
        task = () => firstRun.future;
        final scheduler = newScheduler()..start();

        // When: タスク実行中に stop() を呼び、その後タスクを完了させる
        var stopCompleted = false;
        final stopFuture = scheduler.stop().then((_) => stopCompleted = true);

        // Then: 直後にタイマーは停止し、タスク完了前は stopFuture は未完了
        expect(timers.single.isActive, isFalse);
        await pumpEventQueue();
        expect(stopCompleted, isFalse);

        // When: 進行中タスクを完了する
        firstRun.complete();
        await stopFuture;

        // Then: stopFuture が完了する
        expect(stopCompleted, isTrue);
      },
    );

    // T20
    test(
      'should complete stop without rethrowing when in-flight task fails',
      () async {
        // Given: 失敗予定の進行中タスクで開始済みのスケジューラー
        final firstRun = Completer<void>();
        task = () => firstRun.future;
        final scheduler = newScheduler()..start();

        // When: stop() 待機中に進行中タスクが例外を投げる
        final stopFuture = scheduler.stop();
        firstRun.completeError(StateError('aborted'));

        // Then: stopFuture は正常完了し、errors に StateError が1件記録される
        await expectLater(stopFuture, completes);
        expect(errors, hasLength(1));
        expect(errors.single, isA<StateError>());
      },
    );

    // T21
    test(
      'should be idempotent on repeated stop and ignore subsequent timer ticks',
      () async {
        // Given: start() 後に stop() 済みのスケジューラー
        final scheduler = newScheduler()..start();
        await scheduler.stop();
        expect(count, equals(1));

        // When: 再度 stop() し、その後タイマーが発火する
        await scheduler.stop();
        timers.single.fire();
        await pumpEventQueue();

        // Then: 例外なく完了し、タスクは再実行されない
        expect(count, equals(1));
      },
    );
  });
}
