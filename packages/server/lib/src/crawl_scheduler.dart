import 'dart:async';

/// [task] を開始直後に1回、以降は [interval] ごとに実行する。
/// 前回の実行が終わっていない周期はスキップする。
/// [task] が例外を投げても止まらず、[onError] に渡して次の周期を待つ。
final class CrawlScheduler {
  CrawlScheduler({
    required Future<void> Function() task,
    required Duration interval,
    Timer Function(Duration, void Function(Timer)) createTimer = Timer.periodic,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) : _task = task,
       _interval = interval,
       _createTimer = createTimer,
       _onError = onError;

  final Future<void> Function() _task;
  final Duration _interval;
  final Timer Function(Duration, void Function(Timer)) _createTimer;
  final void Function(Object error, StackTrace stackTrace)? _onError;
  Timer? _timer;
  bool _running = false;

  void start() {
    _timer = _createTimer(_interval, (_) => _run());
    _run();
  }

  void stop() => _timer?.cancel();

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    try {
      await _task();
    } on Object catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    } finally {
      _running = false;
    }
  }
}
