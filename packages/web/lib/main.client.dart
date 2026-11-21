/// クライアント（ブラウザ）のエントリポイント。
///
/// JavaScript にコンパイルされ、ページの読み込み時に実行される。
library;

import 'package:http/http.dart' as http;
import 'package:jaspr/client.dart';

import 'app.dart';
import 'src/api/feeds_api_client.dart';

/// API のベース URL。`--dart-define=API_BASE_URL=...` で切り替える。
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  final client = FeedsApiClient(http.Client(), baseUrl: Uri.parse(_apiBaseUrl));
  runApp(App(loadFeeds: client.fetchFeeds));
}
