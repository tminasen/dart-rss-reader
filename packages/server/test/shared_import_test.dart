import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('shared import', () {
    test('should convert RssFeed to json when imported from shared', () {
      // Given: shared から import した RssFeed
      const feed = RssFeed(
        title: 'tminasen.dev',
        link: 'https://tminasen.dev/',
        description: 'tminasen のブログ',
      );

      // When: JSON に変換する
      final json = feed.toJson();

      // Then: 判別子が rss になる
      expect(json['format'], equals('rss'));
    });
  });
}
