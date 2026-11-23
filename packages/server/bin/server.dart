import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:server/server.dart';
import 'package:server/src/crawl_config.dart';
import 'package:server/src/crawl_scheduler.dart';
import 'package:server/src/feed_crawler.dart';
import 'package:server/src/repositories.dart';
import 'package:server/src/repository_config.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final crawlConfig = CrawlConfig.fromEnvironment(Platform.environment);
  final repositories = await openRepositories(
    RepositoryConfig.fromEnvironment(Platform.environment),
    feedUrl: crawlConfig.feedUrl,
  );
  final crawler = FeedCrawler(
    subscriptions: repositories.subscriptions,
    articles: repositories.articles,
    client: FeedClient(http.Client()),
    feedUrls: [crawlConfig.feedUrl],
    onError: (feedUrl, error, _) =>
        stderr.writeln('crawl failed: $feedUrl: $error'),
  );
  CrawlScheduler(
    task: crawler.crawl,
    interval: crawlConfig.interval,
    onError: (error, _) => stderr.writeln('crawl failed: $error'),
  ).start();
  final server = await shelf_io.serve(
    buildHandler(
      subscriptionRepository: repositories.subscriptions,
      articleRepository: repositories.articles,
      allowedOrigins: {'http://localhost:8081'},
    ),
    InternetAddress.loopbackIPv4,
    8080,
  );
  stdout.writeln('Serving at http://${server.address.host}:${server.port}');
}
