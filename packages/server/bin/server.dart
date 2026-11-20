import 'dart:io';

import 'package:server/server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final server = await shelf_io.serve(
    buildHandler(
      subscriptionRepository: await createDefaultSubscriptionRepository(),
    ),
    InternetAddress.loopbackIPv4,
    8080,
  );
  stdout.writeln('Serving at http://${server.address.host}:${server.port}');
}
