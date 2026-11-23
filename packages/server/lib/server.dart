import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'src/articles_handler.dart';
import 'src/cors_middleware.dart';
import 'src/feeds_handler.dart';
import 'src/new_articles_socket.dart';
import 'src/repository/article_repository.dart';
import 'src/repository/stored_article.dart';
import 'src/repository/subscription_repository.dart';

export 'src/default_subscription_repository.dart';
export 'src/feed_client.dart';
export 'src/feed_fetch_exception.dart';
export 'src/fetch_feed_command.dart';

Handler buildHandler({
  required SubscriptionRepository subscriptionRepository,
  required ArticleRepository articleRepository,
  Stream<StoredArticle> newArticles = const Stream.empty(),
  Set<String> allowedOrigins = const {},
  void Function(String message, bool isError)? logger,
}) {
  final router = Router()
    ..get('/healthz', (Request request) => Response.ok('ok'))
    ..get('/feeds', feedsHandler(subscriptionRepository, articleRepository))
    ..get('/articles', listArticlesHandler(articleRepository))
    ..patch('/articles/<id>', updateArticleHandler(articleRepository))
    ..get(
      '/ws',
      newArticlesSocketHandler(newArticles, allowedOrigins: allowedOrigins),
    );
  return const Pipeline()
      .addMiddleware(logRequests(logger: logger))
      .addMiddleware(corsMiddleware(allowedOrigins: allowedOrigins))
      .addHandler(router.call);
}
