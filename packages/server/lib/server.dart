import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildHandler({void Function(String message, bool isError)? logger}) {
  final router = Router()
    ..get('/healthz', (Request request) => Response.ok('ok'));
  return const Pipeline()
      .addMiddleware(logRequests(logger: logger))
      .addHandler(router.call);
}
