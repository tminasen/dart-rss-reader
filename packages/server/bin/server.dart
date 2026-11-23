import 'dart:io';

import 'package:server/server.dart';
import 'package:server/src/repositories.dart';
import 'package:server/src/repository_config.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final repositories = await openRepositories(
    RepositoryConfig.fromEnvironment(Platform.environment),
  );
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
