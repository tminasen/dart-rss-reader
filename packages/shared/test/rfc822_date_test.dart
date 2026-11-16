import 'dart:math';

import 'package:shared/src/rss/rfc822_date.dart';
import 'package:test/test.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// [dt]（UTC）を [offset]（例: `+0530`）の現地時刻に直して RFC 822 形式で出力する。
String formatRfc822(DateTime dt, String offset) {
  final sign = offset.startsWith('-') ? -1 : 1;
  final minutes =
      sign *
      (int.parse(offset.substring(1, 3)) * 60 + int.parse(offset.substring(3)));
  final local = dt.add(Duration(minutes: minutes));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${_weekdays[local.weekday - 1]}, ${local.day} '
      '${_months[local.month - 1]} ${local.year} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)} $offset';
}

void main() {
  group('parseRfc822Date', () {
    test('should return utc DateTime when value is GMT with weekday', () {
      // Given: 曜日付き GMT の日時
      const value = 'Tue, 14 Apr 2026 00:00:00 GMT';

      // When: 解析する
      final result = parseRfc822Date(value);

      // Then: UTC の DateTime が返る
      expect(result, equals(DateTime.utc(2026, 4, 14)));
      expect(result!.isUtc, isTrue);
    });

    group('numeric offset', () {
      final cases = <String, DateTime>{
        'Mon, 13 Apr 2026 16:17:13 +0900': DateTime.utc(2026, 4, 13, 7, 17, 13),
        'Mon, 13 Apr 2026 16:17:13 -0500': DateTime.utc(
          2026,
          4,
          13,
          21,
          17,
          13,
        ),
        'Mon, 13 Apr 2026 16:17:13 +0530': DateTime.utc(
          2026,
          4,
          13,
          10,
          47,
          13,
        ),
        'Mon, 13 Apr 2026 16:17:13 +0000': DateTime.utc(
          2026,
          4,
          13,
          16,
          17,
          13,
        ),
      };
      for (final entry in cases.entries) {
        test('should subtract offset when value is ${entry.key}', () {
          // Given: 数値オフセット付きの日時
          // When: 解析する
          final result = parseRfc822Date(entry.key);

          // Then: 現地時刻からオフセットを差し引いた UTC になる
          expect(result, equals(entry.value));
        });
      }
    });

    group('named zone', () {
      final cases = <String, int>{
        'GMT': 12,
        'UT': 12,
        'UTC': 12,
        'Z': 12,
        'EST': 17,
        'EDT': 16,
        'CST': 18,
        'CDT': 17,
        'MST': 19,
        'MDT': 18,
        'PST': 20,
        'PDT': 19,
      };
      for (final entry in cases.entries) {
        test('should convert to utc when zone is ${entry.key}', () {
          // Given: 名前付きゾーンの日時
          final value = 'Mon, 13 Apr 2026 12:00:00 ${entry.key}';

          // When: 解析する
          final result = parseRfc822Date(value);

          // Then: ゾーンのオフセットを差し引いた UTC になる
          expect(result, equals(DateTime.utc(2026, 4, 13, entry.value)));
        });
      }
    });

    test('should parse when weekday is omitted', () {
      // Given: 曜日を省略した日時
      // When: 解析する
      final result = parseRfc822Date('13 Apr 2026 16:17:13 GMT');

      // Then: UTC の DateTime が返る
      expect(result, equals(DateTime.utc(2026, 4, 13, 16, 17, 13)));
    });

    test('should parse when seconds are omitted', () {
      // Given: 秒を省略した日時
      // When: 解析する
      final result = parseRfc822Date('Mon, 13 Apr 2026 16:17 GMT');

      // Then: 秒は 0 になる
      expect(result, equals(DateTime.utc(2026, 4, 13, 16, 17)));
    });

    test('should parse when day is single digit', () {
      // Given: 1桁の日
      // When: 解析する
      final result = parseRfc822Date('Mon, 6 Apr 2026 00:00:00 GMT');

      // Then: UTC の DateTime が返る
      expect(result, equals(DateTime.utc(2026, 4, 6)));
    });

    test('should ignore surrounding whitespace when value is padded', () {
      // Given: 前後に空白・改行がある日時
      // When: 解析する
      final result = parseRfc822Date('\n  Tue, 14 Apr 2026 00:00:00 GMT  \n');

      // Then: 空白を無視して解析できる
      expect(result, equals(DateTime.utc(2026, 4, 14)));
    });

    group('invalid format', () {
      final cases = <String, String>{
        '空文字': '',
        'ISO 8601 形式': '2026-04-14T00:00:00Z',
        '不明な月名': 'Tue, 14 Foo 2026 00:00:00 GMT',
        '非対応のゾーン名': 'Tue, 14 Apr 2026 00:00:00 JST',
        '2桁の年': 'Tue, 14 Apr 26 00:00:00 GMT',
        '3文字でない曜日名': 'Tuesday, 14 Apr 2026 00:00:00 GMT',
        '不明な曜日名': 'Foo, 14 Apr 2026 00:00:00 GMT',
      };
      for (final entry in cases.entries) {
        test('should return null when value is ${entry.key}', () {
          // Given: 解釈できない日時文字列
          // When: 解析する
          final result = parseRfc822Date(entry.value);

          // Then: null が返る
          expect(result, isNull);
        });
      }
    });

    group('date boundary', () {
      test('should parse when day is the last day of a 30-day month', () {
        // Given: 4月30日
        // When: 解析する
        final result = parseRfc822Date('30 Apr 2026 00:00:00 GMT');

        // Then: 有効な日付として返る
        expect(result, equals(DateTime.utc(2026, 4, 30)));
      });

      test('should return null when day does not exist in the month', () {
        // Given: 存在しない4月31日
        // When: 解析する
        final result = parseRfc822Date('31 Apr 2026 00:00:00 GMT');

        // Then: 5月1日に繰り上げず null が返る
        expect(result, isNull);
      });

      test('should parse when Feb 29 is in a leap year', () {
        // Given: うるう年の2月29日
        // When: 解析する
        final result = parseRfc822Date('29 Feb 2024 00:00:00 GMT');

        // Then: 有効な日付として返る
        expect(result, equals(DateTime.utc(2024, 2, 29)));
      });

      test('should return null when Feb 29 is in a common year', () {
        // Given: 平年の2月29日
        // When: 解析する
        final result = parseRfc822Date('29 Feb 2026 00:00:00 GMT');

        // Then: null が返る
        expect(result, isNull);
      });
    });

    group('time boundary', () {
      test('should parse when time is 23:59:59', () {
        // Given: 時刻の最大値
        // When: 解析する
        final result = parseRfc822Date('14 Apr 2026 23:59:59 GMT');

        // Then: 有効な時刻として返る
        expect(result, equals(DateTime.utc(2026, 4, 14, 23, 59, 59)));
      });

      test('should return null when hour is 24', () {
        // Given: 時が 24
        // When: 解析する
        final result = parseRfc822Date('14 Apr 2026 24:00:00 GMT');

        // Then: 翌日に繰り上げず null が返る
        expect(result, isNull);
      });

      test('should return null when minute is 60', () {
        // Given: 分が 60
        // When: 解析する
        final result = parseRfc822Date('14 Apr 2026 23:60:00 GMT');

        // Then: null が返る
        expect(result, isNull);
      });

      test('should return null when day is 0', () {
        // Given: 日が 0
        // When: 解析する
        final result = parseRfc822Date('0 Apr 2026 00:00:00 GMT');

        // Then: null が返る
        expect(result, isNull);
      });
    });

    group('round trip', () {
      // 2099-12-31T23:59:59Z のエポック秒
      const maxEpochSeconds = 4102444799;
      final random = Random(42);
      final instants = List.generate(
        500,
        (_) => DateTime.fromMillisecondsSinceEpoch(
          random.nextInt(maxEpochSeconds + 1) * 1000,
          isUtc: true,
        ),
      );
      for (final offset in ['-0800', '-0500', '+0000', '+0530', '+0900']) {
        test('should restore the same instant when offset is $offset', () {
          // Given: 500 件の UTC 日時を同じオフセットで書式化した文字列
          for (final dt in instants) {
            final formatted = formatRfc822(dt, offset);

            // When: 解析する
            final result = parseRfc822Date(formatted);

            // Then: 元の瞬間に戻る
            expect(result, equals(dt), reason: formatted);
          }
        });
      }
    });
  });
}
