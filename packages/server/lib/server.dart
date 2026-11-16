import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

export 'src/feed_client.dart';
export 'src/feed_fetch_exception.dart';
export 'src/fetch_feed_command.dart';

Handler buildHandler({void Function(String message, bool isError)? logger}) {
  final router = Router()
    ..get('/healthz', (Request request) => Response.ok('ok'));
  return const Pipeline()
      .addMiddleware(logRequests(logger: logger))
      .addHandler(router.call);
}
