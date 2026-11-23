import 'dart:async';

/// シグナル受信時にサーバーと関連リソースを順にクローズして終了を待つ。
///
/// 途中のクローズ処理が失敗しても [onError] へ通知したうえで残りをすべて実行し、
/// 特に SQLite リポジトリのクローズ漏れを防ぐ。
Future<void> waitForShutdown({
  required Stream<void> signals,
  required Future<void> Function() closeServer,
  required void Function() closeHttpClient,
  required Future<void> Function() stopScheduler,
  required Future<void> Function() closeCrawler,
  required void Function() closeRepositories,
  void Function(Object error, StackTrace stackTrace)? onError,
}) {
  final completer = Completer<void>();
  var closing = false;
  late final StreamSubscription<void> subscription;

  Future<void> closeAll() async {
    await _runStep(closeServer, onError);
    await _runStep(closeHttpClient, onError);
    await _runStep(stopScheduler, onError);
    await _runStep(closeCrawler, onError);
    await _runStep(closeRepositories, onError);
  }

  subscription = signals.listen(
    (_) async {
      if (closing) return;
      closing = true;
      await _runStep(subscription.cancel, onError);
      await closeAll();
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
    onDone: () {
      if (!closing && !completer.isCompleted) {
        completer.complete();
      }
    },
  );
  return completer.future;
}

Future<void> _runStep(
  FutureOr<void> Function() action,
  void Function(Object error, StackTrace stackTrace)? onError,
) async {
  try {
    await action();
  } on Object catch (error, stackTrace) {
    onError?.call(error, stackTrace);
  }
}
