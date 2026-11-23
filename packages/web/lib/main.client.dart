/// クライアント（ブラウザ）のエントリポイント。
///
/// JavaScript にコンパイルされ、ページの読み込み時に実行される。
library;

import 'package:http/http.dart' as http;
import 'package:jaspr/client.dart';

import 'app.dart';
import 'src/api/articles_api_client.dart';
import 'src/api/feeds_api_client.dart';
import 'src/realtime/browser_realtime_socket.dart';
import 'src/realtime/new_articles_feed.dart';
import 'src/realtime/web_socket_uri.dart';

/// API のベース URL。`--dart-define=API_BASE_URL=...` で切り替える。
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  final httpClient = http.Client();
  final baseUrl = Uri.parse(_apiBaseUrl);
  final feedsClient = FeedsApiClient(httpClient, baseUrl: baseUrl);
  final articlesClient = ArticlesApiClient(httpClient, baseUrl: baseUrl);
  final webSocketUri = webSocketUriFrom(baseUrl);
  final newArticlesFeed = NewArticlesFeed(
    connect: () => BrowserRealtimeSocket(webSocketUri),
  )..start();
  runApp(
    App(
      loadFeeds: feedsClient.fetchFeeds,
      loadArticles: articlesClient.fetchArticles,
      updateArticleRead: articlesClient.updateArticleRead,
      newArticles: newArticlesFeed.articles,
      connectionStatus: newArticlesFeed.status,
    ),
  );
}
