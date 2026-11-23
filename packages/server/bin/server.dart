import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:server/server.dart';
import 'package:server/src/crawl_config.dart';
import 'package:server/src/crawl_scheduler.dart';
import 'package:server/src/feed_crawler.dart';
import 'package:server/src/repositories.dart';
import 'package:server/src/repository_config.dart';
import 'package:server/src/server_config.dart';
import 'package:server/src/shutdown.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final serverConfig = ServerConfig.fromEnvironment(Platform.environment);
  final crawlConfig = CrawlConfig.fromEnvironment(Platform.environment);
  final repositories = await openRepositories(
    RepositoryConfig.fromEnvironment(Platform.environment),
    feedUrl: crawlConfig.feedUrl,
  );
  final httpClient = http.Client();
  final crawler = FeedCrawler(
    subscriptions: repositories.subscriptions,
    articles: repositories.articles,
    client: FeedClient(httpClient),
    feedUrls: [crawlConfig.feedUrl],
    onError: (feedUrl, error, _) =>
        stderr.writeln('crawl failed: $feedUrl: $error'),
  );
  final scheduler = CrawlScheduler(
    task: crawler.crawl,
    interval: crawlConfig.interval,
    onError: (error, _) => stderr.writeln('crawl failed: $error'),
  )..start();
  final server = await shelf_io.serve(
    buildHandler(
      subscriptionRepository: repositories.subscriptions,
      articleRepository: repositories.articles,
      newArticles: crawler.newArticles,
      allowedOrigins: serverConfig.allowedOrigins,
    ),
    serverConfig.host,
    serverConfig.port,
  );
  stdout.writeln('Serving at http://${server.address.host}:${server.port}');

  await waitForShutdown(
    signals: _watchShutdownSignals(),
    // Keep-Alive や WebSocket 接続で終了が詰まり、DB クローズに到達できない事態を防ぐ。
    closeServer: () => server.close(force: true),
    closeHttpClient: httpClient.close,
    stopScheduler: scheduler.stop,
    closeCrawler: crawler.close,
    closeRepositories: repositories.close,
    onError: (error, _) => stderr.writeln('shutdown failed: $error'),
  );
}

Stream<void> _watchShutdownSignals() {
  late final StreamController<void> controller;
  final subscriptions = <StreamSubscription<ProcessSignal>>[];
  controller = StreamController<void>(
    onListen: () {
      subscriptions.add(ProcessSignal.sigint.watch().listen(controller.add));
      if (!Platform.isWindows) {
        subscriptions.add(ProcessSignal.sigterm.watch().listen(controller.add));
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
  return controller.stream;
}
