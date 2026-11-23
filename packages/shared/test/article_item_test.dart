import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';

final rssArticleA = RssArticle(
  title: 'Angularを使ってボードゲームの得点計算ツールを作った話',
  link: 'https://tminasen.dev/blog/1',
  pubDate: DateTime(2026, 4, 14),
  enclosure: const RssEnclosure(
    url: 'https://tminasen.dev/images/1.png',
    length: 0,
    type: 'image/png',
  ),
);

final atomArticleA = AtomArticle(
  id: 'atom-1',
  title: 'Atom記事',
  link: 'https://example.com/atom/1',
  published: DateTime(2026, 1, 5),
  updated: DateTime(2026, 1, 6),
);

final unreadItemA = ArticleItem(
  id: 'a-1',
  feedId: 'f-1',
  isRead: false,
  article: rssArticleA,
);

final unreadItemC = ArticleItem(
  id: 'a-3',
  feedId: 'f-1',
  isRead: false,
  article: atomArticleA,
);

final itemAJson = <String, dynamic>{
  'id': 'a-1',
  'feedId': 'f-1',
  'isRead': false,
  'article': rssArticleA.toJson(),
};

final itemCJson = <String, dynamic>{
  'id': 'a-3',
  'feedId': 'f-1',
  'isRead': false,
  'article': atomArticleA.toJson(),
};

void main() {
  group('ArticleItem', () {
    group('fromJson and toJson', () {
      // T3
      test(
        'should round-trip RSS article item between JSON and ArticleItem',
        () {
          // Given: RSS 記事を含む itemAJson

          // When: fromJson で復元し toJson で再変換する
          final restored = ArticleItem.fromJson(itemAJson);
          final encoded = restored.toJson();

          // Then: unreadItemA と等価で、toJson が itemAJson と等価になる
          expect(restored, equals(unreadItemA));
          expect(encoded, equals(itemAJson));
        },
      );

      // T4
      test(
        'should round-trip Atom article item between JSON and ArticleItem',
        () {
          // Given: Atom 記事を含む itemCJson

          // When: fromJson で復元し toJson で再変換する
          final restored = ArticleItem.fromJson(itemCJson);
          final encoded = restored.toJson();

          // Then: unreadItemC と等価で、toJson が itemCJson と等価になる
          expect(restored, equals(unreadItemC));
          expect(encoded, equals(itemCJson));
        },
      );

      // T5
      test(
        'should throw TypeError when required field is missing or wrong type',
        () {
          // Given: isRead が bool でない JSON と id 欠損の JSON
          final wrongTypeJson = <String, dynamic>{
            'id': 'a-1',
            'feedId': 'f-1',
            'isRead': 'yes',
            'article': rssArticleA.toJson(),
          };
          final missingIdJson = <String, dynamic>{
            'feedId': 'f-1',
            'isRead': false,
            'article': rssArticleA.toJson(),
          };

          // When / Then: TypeError が送出される
          expect(
            () => ArticleItem.fromJson(wrongTypeJson),
            throwsA(isA<TypeError>()),
          );
          expect(
            () => ArticleItem.fromJson(missingIdJson),
            throwsA(isA<TypeError>()),
          );
        },
      );
    });

    group('P1: JSON round-trip invariant', () {
      const ids = ['1', 'a/b', '日本語-id'];
      const feedIds = ['f-1', 'feed_2'];
      final dates = [DateTime.utc(1970, 1, 1), DateTime(2026, 4, 14, 9, 30)];

      for (final id in ids) {
        for (final feedId in feedIds) {
          for (final isRead in [true, false]) {
            for (final date in dates) {
              for (final withOptional in [true, false]) {
                for (final withEnclosure in [true, false]) {
                  test(
                    'should preserve RssArticle item when id=$id feedId=$feedId isRead=$isRead date=$date optional=$withOptional enclosure=$withEnclosure',
                    () {
                      // Given: 入力ドメインの各要素を組み合わせた RSS ArticleItem
                      final item = ArticleItem(
                        id: id,
                        feedId: feedId,
                        isRead: isRead,
                        article: RssArticle(
                          title: withOptional ? 'タイトル-$id' : null,
                          link: withOptional ? 'https://example.com/$id' : null,
                          guid: withOptional ? 'guid-$id' : null,
                          pubDate: withOptional ? date : null,
                          description: withOptional ? '<p>本文</p>' : null,
                          enclosure: withEnclosure
                              ? const RssEnclosure(
                                  url: 'https://example.com/a.png',
                                  length: 1024,
                                  type: 'image/png',
                                )
                              : null,
                        ),
                      );

                      // When: toJson と JSON 往復を経て fromJson する
                      final directRestored = ArticleItem.fromJson(
                        item.toJson(),
                      );
                      final stringRestored = ArticleItem.fromJson(
                        jsonDecode(jsonEncode(item.toJson()))
                            as Map<String, dynamic>,
                      );

                      // Then: 元の item と等価
                      expect(directRestored, equals(item));
                      expect(stringRestored, equals(item));
                    },
                  );
                }

                test(
                  'should preserve AtomArticle item when id=$id feedId=$feedId isRead=$isRead date=$date optional=$withOptional',
                  () {
                    // Given: 入力ドメインの各要素を組み合わせた Atom ArticleItem
                    final item = ArticleItem(
                      id: id,
                      feedId: feedId,
                      isRead: isRead,
                      article: AtomArticle(
                        id: 'atom-$id',
                        title: 'Atom-$id',
                        updated: date,
                        link: withOptional ? 'https://example.com/$id' : null,
                        published: withOptional ? date : null,
                        summary: withOptional ? '要約' : null,
                      ),
                    );

                    // When: toJson と JSON 往復を経て fromJson する
                    final directRestored = ArticleItem.fromJson(item.toJson());
                    final stringRestored = ArticleItem.fromJson(
                      jsonDecode(jsonEncode(item.toJson()))
                          as Map<String, dynamic>,
                    );

                    // Then: 元の item と等価
                    expect(directRestored, equals(item));
                    expect(stringRestored, equals(item));
                  },
                );
              }
            }
          }
        }
      }
    });
  });
}
