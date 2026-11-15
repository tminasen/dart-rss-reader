import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';

const strings = ['', 'tminasen.dev', '日本語 & <tag> "quote"'];

final dates = [
  DateTime.utc(1970, 1, 1),
  DateTime.utc(2026, 11, 15, 9, 30, 0, 123),
  DateTime.utc(9999, 12, 31, 23, 59, 59, 999),
];

const enclosureLengths = [0, 2147483647];

Map<String, dynamic> viaJsonString(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('Feed round trip via JSON string', () {
    for (final s in strings) {
      for (final d in dates) {
        for (final withOptional in [true, false]) {
          final label = 's="$s" date=$d optional=$withOptional';

          test('should restore RssFeed when $label', () {
            // Given: 入力ドメインの組み合わせから作った RssFeed
            final feed = RssFeed(
              title: s,
              link: s,
              description: s,
              lastBuildDate: withOptional ? d : null,
              language: withOptional ? s : null,
              imageUrl: withOptional ? s : null,
            );

            // When: JSON 文字列を経由して復元する
            final restored = Feed.fromJson(viaJsonString(feed.toJson()));

            // Then: 元の値と等しい
            expect(restored, equals(feed));
          });

          test('should restore AtomFeed when $label', () {
            // Given: 入力ドメインの組み合わせから作った AtomFeed
            final feed = AtomFeed(
              id: s,
              title: s,
              updated: d,
              link: withOptional ? s : null,
              subtitle: withOptional ? s : null,
            );

            // When: JSON 文字列を経由して復元する
            final restored = Feed.fromJson(viaJsonString(feed.toJson()));

            // Then: 元の値と等しい
            expect(restored, equals(feed));
          });
        }
      }
    }
  });

  group('Article round trip via JSON string', () {
    for (final s in strings) {
      for (final d in dates) {
        for (final withOptional in [true, false]) {
          final label = 's="$s" date=$d optional=$withOptional';

          test('should restore RssArticle without enclosure when $label', () {
            // Given: enclosure が null の RssArticle
            final article = RssArticle(
              title: withOptional ? s : null,
              link: withOptional ? s : null,
              guid: withOptional ? s : null,
              pubDate: withOptional ? d : null,
              description: withOptional ? s : null,
            );

            // When: JSON 文字列を経由して復元する
            final restored = Article.fromJson(viaJsonString(article.toJson()));

            // Then: 元の値と等しい
            expect(restored, equals(article));
          });

          for (final length in enclosureLengths) {
            test(
              'should restore RssArticle with enclosure length $length when $label',
              () {
                // Given: enclosure を持つ RssArticle
                final article = RssArticle(
                  title: withOptional ? s : null,
                  link: withOptional ? s : null,
                  guid: withOptional ? s : null,
                  pubDate: withOptional ? d : null,
                  description: withOptional ? s : null,
                  enclosure: RssEnclosure(url: s, length: length, type: s),
                );

                // When: JSON 文字列を経由して復元する
                final restored = Article.fromJson(
                  viaJsonString(article.toJson()),
                );

                // Then: 元の値と等しい
                expect(restored, equals(article));
              },
            );
          }

          test('should restore AtomArticle when $label', () {
            // Given: 入力ドメインの組み合わせから作った AtomArticle
            final article = AtomArticle(
              id: s,
              title: s,
              updated: d,
              link: withOptional ? s : null,
              published: withOptional ? d : null,
              summary: withOptional ? s : null,
            );

            // When: JSON 文字列を経由して復元する
            final restored = Article.fromJson(viaJsonString(article.toJson()));

            // Then: 元の値と等しい
            expect(restored, equals(article));
          });
        }
      }
    }
  });
}
