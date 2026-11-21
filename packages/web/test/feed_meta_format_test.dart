import 'package:test/test.dart';
import 'package:web_app/src/feed_meta_format.dart';

void main() {
  group('formatFeedMeta', () {
    test('should format datetime and count when lastFetchedAt is set', () {
      // Given: ローカル時刻の最終取得日時と件数
      final lastFetchedAt = DateTime(2026, 11, 15, 10, 30);

      // When: 整形する
      final text = formatFeedMeta(
        lastFetchedAt: lastFetchedAt,
        articleCount: 10,
      );

      // Then: Figma の形式になる
      expect(text, equals('最終取得 2026/11/15 10:30 ・ 全10件'));
    });

    test('should zero-pad month, day, hour and minute when they are single '
        'digit', () {
      // Given: 1桁の月・日・時・分
      final lastFetchedAt = DateTime(2026, 1, 5, 9, 5);

      // When: 整形する
      final text = formatFeedMeta(
        lastFetchedAt: lastFetchedAt,
        articleCount: 3,
      );

      // Then: ゼロ埋めされる
      expect(text, equals('最終取得 2026/01/05 09:05 ・ 全3件'));
    });

    test('should show 未取得 when lastFetchedAt is null', () {
      // Given: 未取得（null）
      // When: 整形する
      final text = formatFeedMeta(lastFetchedAt: null, articleCount: 0);

      // Then: 「未取得」と出る
      expect(text, equals('最終取得 未取得 ・ 全0件'));
    });

    test(
      'should convert UTC datetime to local time when lastFetchedAt is UTC',
      () {
        // Given: UTC の最終取得日時
        final utc = DateTime.utc(2026, 11, 19, 9);
        final local = utc.toLocal();

        // When: 整形する
        final text = formatFeedMeta(lastFetchedAt: utc, articleCount: 1);

        // Then: ローカル時刻で表示される
        String two(int n) => n.toString().padLeft(2, '0');
        expect(
          text,
          equals(
            '最終取得 ${local.year}/${two(local.month)}/${two(local.day)} '
            '${two(local.hour)}:${two(local.minute)} ・ 全1件',
          ),
        );
      },
    );

    test('should format max-width values when date is year end and count is '
        '99999', () {
      // Given: 年末23:59 と桁数の多い件数
      final lastFetchedAt = DateTime(2026, 12, 31, 23, 59);

      // When: 整形する
      final text = formatFeedMeta(
        lastFetchedAt: lastFetchedAt,
        articleCount: 99999,
      );

      // Then: 書式が崩れない
      expect(text, equals('最終取得 2026/12/31 23:59 ・ 全99999件'));
    });

    test('should format min-width values when date is year start and count is '
        '0', () {
      // Given: 年始0:00 と件数0
      final lastFetchedAt = DateTime(2026, 1, 1, 0, 0);

      // When: 整形する
      final text = formatFeedMeta(
        lastFetchedAt: lastFetchedAt,
        articleCount: 0,
      );

      // Then: 書式が崩れない
      expect(text, equals('最終取得 2026/01/01 00:00 ・ 全0件'));
    });
  });
}
