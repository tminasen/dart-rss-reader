import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_app/src/realtime/new_article_message.dart';

final newRssArticle = RssArticle(
  title: '新着記事のタイトル',
  link: 'https://tminasen.dev/blog/new',
  pubDate: DateTime(2026, 11, 15),
  enclosure: null,
);

final newItem = ArticleItem(
  id: 'n-1',
  feedId: 'f-1',
  isRead: false,
  article: newRssArticle,
);

final newItemJson = jsonEncode(newItem.toJson());

void main() {
  group('parseNewArticleMessage', () {
    test('should return ArticleItem when message is ArticleItem JSON', () {
      // Given: ArticleItem の JSON 文字列 newItemJson

      // When: parseNewArticleMessage を呼ぶ
      final item = parseNewArticleMessage(newItemJson);

      // Then: newItem と等しい ArticleItem が返る
      expect(item, equals(newItem));
    });

    test('should return null when message is not JSON', () {
      // Given: JSON でない文字列

      // When: parseNewArticleMessage を呼ぶ
      final item = parseNewArticleMessage('not json');

      // Then: 例外を投げず null が返る
      expect(item, isNull);
    });

    test('should return null when required keys are missing', () {
      // Given: キーが欠けた JSON

      // When: parseNewArticleMessage を呼ぶ
      final item = parseNewArticleMessage('{"id":"n-1"}');

      // Then: 例外を投げず null が返る
      expect(item, isNull);
    });
  });
}
