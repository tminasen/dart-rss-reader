import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared/shared.dart';

import 'api_exception.dart';

/// server の `GET /feeds` を呼ぶ API クライアント。
///
/// 失敗は [ApiException] の下位型で知らせる。
final class FeedsApiClient {
  FeedsApiClient(
    this._client, {
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client _client;
  final Uri baseUrl;
  final Duration timeout;

  Future<List<FeedSummary>> fetchFeeds() async {
    final url = baseUrl.resolve('/feeds');
    final http.Response response;
    try {
      response = await _client.get(url).timeout(timeout);
    } on TimeoutException {
      throw ApiTimeoutException('Request timed out after $timeout: $url');
    } on http.ClientException catch (e) {
      throw ApiConnectionException('Failed to connect to $url: ${e.message}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiHttpStatusException(response.statusCode);
    }
    try {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return [
        for (final item in decoded)
          FeedSummary.fromJson(item as Map<String, dynamic>),
      ];
    } on FormatException catch (e) {
      throw ApiFormatException('Response body is not valid JSON: ${e.message}');
    } on TypeError catch (e) {
      throw ApiFormatException('Unexpected response shape: $e');
    }
  }
}
