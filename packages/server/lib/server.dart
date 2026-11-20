import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'src/feeds_handler.dart';
import 'src/repository/subscription_repository.dart';

export 'src/default_subscription_repository.dart';
export 'src/feed_client.dart';
export 'src/feed_fetch_exception.dart';
export 'src/fetch_feed_command.dart';

Handler buildHandler({
  required SubscriptionRepository subscriptionRepository,
  void Function(String message, bool isError)? logger,
}) {
  final router = Router()
    ..get('/healthz', (Request request) => Response.ok('ok'))
    ..get('/feeds', feedsHandler(subscriptionRepository));
  return const Pipeline()
      .addMiddleware(logRequests(logger: logger))
      .addHandler(router.call);
}
