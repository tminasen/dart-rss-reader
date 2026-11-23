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
  Future<void>? _currentRun;
  bool _stopped = false;

  void start() {
    _stopped = false;
    _timer = _createTimer(_interval, (_) => _run());
    _run();
  }

  /// タイマーを直ちに停止し、進行中の実行があれば完了まで待つ。
  Future<void> stop() async {
    _stopped = true;
    _timer?.cancel();
    await _currentRun;
  }

  Future<void> _run() async {
    if (_stopped || _currentRun != null) return;
    final completer = Completer<void>();
    _currentRun = completer.future;
    try {
      await _task();
    } on Object catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    } finally {
      _currentRun = null;
      completer.complete();
    }
  }
}
