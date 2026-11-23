import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'repository/article_repository.dart';
import 'repository/repository_exception.dart';
import 'repository/stored_article.dart';

const _defaultLimit = 20;
const _maxLimit = 100;

Handler listArticlesHandler(ArticleRepository repository) {
  return (Request request) async {
    final query = request.url.queryParameters;
    final limitParam = query['limit'];
    final limit = limitParam == null ? _defaultLimit : int.tryParse(limitParam);
    if (limit == null || limit < 1 || limit > _maxLimit) {
      return _errorResponse(
        400,
        'limit must be an integer between 1 and $_maxLimit',
      );
    }
    final offsetParam = query['offset'];
    final offset = offsetParam == null ? 0 : int.tryParse(offsetParam);
    if (offset == null || offset < 0) {
      return _errorResponse(400, 'offset must be an integer >= 0');
    }
    final unreadParam = query['unread'];
    if (unreadParam != null &&
        unreadParam != 'true' &&
        unreadParam != 'false') {
      return _errorResponse(400, 'unread must be true or false');
    }
    final articles = await repository.find(
      feedId: query['feedId'],
      unreadOnly: unreadParam == 'true',
      limit: limit,
      offset: offset,
    );
    return _jsonResponse(200, {
      'items': articles.map((stored) => stored.toJson()).toList(),
      'limit': limit,
      'offset': offset,
    });
  };
}

Future<Response> Function(Request request, String id) updateArticleHandler(
  ArticleRepository repository,
) {
  return (Request request, String id) async {
    final Object? body;
    try {
      body = jsonDecode(await request.readAsString());
    } on FormatException {
      return _errorResponse(400, 'body must be valid JSON');
    }
    final isRead = body is Map<String, Object?> ? body['isRead'] : null;
    if (isRead is! bool) {
      return _errorResponse(400, 'body must be {"isRead": <boolean>}');
    }
    final StoredArticle updated;
    try {
      updated = await repository.setRead(id, isRead: isRead);
    } on ArticleNotFoundException {
      return _errorResponse(404, 'article not found: $id');
    }
    return _jsonResponse(200, updated.toJson());
  };
}

Response _errorResponse(int statusCode, String message) =>
    _jsonResponse(statusCode, {'error': message});

Response _jsonResponse(int statusCode, Object? body) => Response(
  statusCode,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json'},
);
