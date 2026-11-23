import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared/shared.dart';

import 'api_exception.dart';

/// server の `/articles` 系エンドポイントを呼ぶ API クライアント。
///
/// 失敗は [ApiException] の下位型で知らせる。
final class ArticlesApiClient {
  ArticlesApiClient(
    this._client, {
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client _client;
  final Uri baseUrl;
  final Duration timeout;

  Future<List<ArticleItem>> fetchArticles({int limit = 100}) async {
    final url = baseUrl
        .resolve('/articles')
        .replace(queryParameters: {'limit': '$limit'});
    final response = await _send(url, () => _client.get(url));
    return _parseJson(response, (decoded) {
      final map = decoded as Map<String, dynamic>;
      final items = map['items'] as List<dynamic>;
      return [
        for (final item in items)
          ArticleItem.fromJson(item as Map<String, dynamic>),
      ];
    });
  }

  Future<ArticleItem> updateArticleRead(
    String id, {
    required bool isRead,
  }) async {
    final url = baseUrl.resolve('/articles/${Uri.encodeComponent(id)}');
    final response = await _send(
      url,
      () => _client.patch(
        url,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'isRead': isRead}),
      ),
    );
    return _parseJson(
      response,
      (decoded) => ArticleItem.fromJson(decoded as Map<String, dynamic>),
    );
  }

  Future<http.Response> _send(
    Uri url,
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw ApiTimeoutException('Request timed out after $timeout: $url');
    } on http.ClientException catch (e) {
      throw ApiConnectionException('Failed to connect to $url: ${e.message}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiHttpStatusException(response.statusCode);
    }
    return response;
  }

  T _parseJson<T>(http.Response response, T Function(Object? decoded) parse) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return parse(decoded);
    } on FormatException catch (e) {
      throw ApiFormatException('Response body is not valid JSON: ${e.message}');
    } on TypeError catch (e) {
      throw ApiFormatException('Unexpected response shape: $e');
    }
  }
}
