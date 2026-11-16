import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:server/server.dart';

Future<void> main(List<String> arguments) async {
  final httpClient = http.Client();
  try {
    exitCode = await runFetchFeedCommand(
      arguments,
      client: FeedClient(httpClient),
      out: stdout,
      err: stderr,
    );
  } finally {
    httpClient.close();
  }
}
