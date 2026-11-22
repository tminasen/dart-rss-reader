import 'package:shared/shared.dart';
import 'package:test/test.dart';

const feedUrlA = 'https://tminasen.dev/rss/feed.xml';
const feedUrlB = 'https://example.com/atom.xml';

final summaryJson = {
  'title': 'tminasen.dev',
  'url': 'https://tminasen.dev/rss/feed.xml',
  'lastFetchedAt': '2026-11-19T09:00:00.000Z',
  'articleCount': 10,
};

final summaryA = FeedSummary(
  title: 'tminasen.dev',
  url: 'https://tminasen.dev/rss/feed.xml',
  lastFetchedAt: DateTime.utc(2026, 11, 19, 9),
  articleCount: 10,
);

void main() {
  group('FeedSummary', () {
    group('fromJson', () {
      test('should restore all fields when json has every field', () {
        // Given: 全項目ありの JSON
        // When: JSON から復元する
        final summary = FeedSummary.fromJson(summaryJson);

        // Then: summaryA と等しい
        expect(summary, equals(summaryA));
      });

      test(
        'should restore null title and lastFetchedAt when they are null',
        () {
          // Given: title と lastFetchedAt が null の JSON
          final json = {
            'title': null,
            'url': 'https://example.com/atom.xml',
            'lastFetchedAt': null,
            'articleCount': 0,
          };

          // When: JSON から復元する
          final summary = FeedSummary.fromJson(json);

          // Then: null を保ったまま復元される
          expect(
            summary,
            equals(
              const FeedSummary(
                title: null,
                url: 'https://example.com/atom.xml',
                lastFetchedAt: null,
                articleCount: 0,
              ),
            ),
          );
        },
      );
    });

    group('toJson', () {
      test('should output UTC datetime as ISO 8601 string when converted', () {
        // Given: UTC 日時を持つ summaryA
        // When: JSON に変換する
        final json = summaryA.toJson();

        // Then: summaryJson と等しい
        expect(json, equals(summaryJson));
      });
    });

    group('P1: round trip', () {
      final titles = <String?>[null, '', 'tminasen.dev', '水無瀬のプログラミング日記feed'];
      final urls = [feedUrlA, feedUrlB];
      final dates = <DateTime?>[
        null,
        DateTime.utc(2000, 1, 1),
        DateTime.utc(2026, 11, 19, 9),
        DateTime.utc(2099, 12, 31, 23, 59, 59, 999),
      ];
      final counts = [0, 1, 1000];

      for (final title in titles) {
        for (final url in urls) {
          for (final date in dates) {
            for (final count in counts) {
              test('should equal the original when title=$title url=$url '
                  'lastFetchedAt=$date articleCount=$count '
                  'is converted to json and back', () {
                // Given: 入力ドメインの1組み合わせ
                final original = FeedSummary(
                  title: title,
                  url: url,
                  lastFetchedAt: date,
                  articleCount: count,
                );

                // When: JSON に変換して戻す
                final restored = FeedSummary.fromJson(original.toJson());

                // Then: 元の値と等しい
                expect(restored, equals(original));
              });
            }
          }
        }
      }
    });
  });
}
