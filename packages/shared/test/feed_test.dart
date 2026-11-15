import 'package:shared/shared.dart';
import 'package:test/test.dart';

final rssFeed = RssFeed(
  title: 'tminasen.dev',
  link: 'https://tminasen.dev/',
  description: 'tminasen のブログ',
  lastBuildDate: DateTime.utc(2026, 11, 15, 9, 30),
  language: 'ja',
  imageUrl: 'https://tminasen.dev/icon.png',
);

final rssFeedJson = <String, dynamic>{
  'format': 'rss',
  'title': 'tminasen.dev',
  'link': 'https://tminasen.dev/',
  'description': 'tminasen のブログ',
  'lastBuildDate': '2026-11-15T09:30:00.000Z',
  'language': 'ja',
  'imageUrl': 'https://tminasen.dev/icon.png',
};

final atomFeed = AtomFeed(
  id: 'tag:example.com,2026:feed',
  title: 'Example Atom',
  updated: DateTime.utc(2026, 11, 14),
  link: 'https://example.com/',
  subtitle: 'Atom のサンプル',
);

final atomFeedJson = <String, dynamic>{
  'format': 'atom',
  'id': 'tag:example.com,2026:feed',
  'title': 'Example Atom',
  'updated': '2026-11-14T00:00:00.000Z',
  'link': 'https://example.com/',
  'subtitle': 'Atom のサンプル',
};

void main() {
  group('RssFeed', () {
    group('toJson', () {
      test('should return json with format rss when converted', () {
        // Given: RssFeed
        // When: JSON に変換する
        final json = rssFeed.toJson();

        // Then: 判別子 rss 付きの JSON になる
        expect(json, equals(rssFeedJson));
      });
    });

    group('Feed.fromJson', () {
      test('should restore RssFeed when format is rss', () {
        // Given: format が rss の JSON
        // When: Feed.fromJson を呼ぶ
        final feed = Feed.fromJson(rssFeedJson);

        // Then: RssFeed として復元される
        expect(feed, isA<RssFeed>());
        expect(feed, equals(rssFeed));
      });
    });

    group('common getters', () {
      test('should return title and link when accessed as Feed', () {
        // Given: Feed 型として保持した RssFeed
        final Feed feed = rssFeed;

        // When: 共通項目を取得する
        final title = feed.title;
        final link = feed.link;

        // Then: RssFeed の値が返る
        expect(title, equals('tminasen.dev'));
        expect(link, equals('https://tminasen.dev/'));
      });
    });

    group('equality', () {
      test('should be equal and share hashCode when values are the same', () {
        // Given: 同じ値で別に生成した RssFeed
        final other = RssFeed(
          title: 'tminasen.dev',
          link: 'https://tminasen.dev/',
          description: 'tminasen のブログ',
          lastBuildDate: DateTime.utc(2026, 11, 15, 9, 30),
          language: 'ja',
          imageUrl: 'https://tminasen.dev/icon.png',
        );

        // When: 比較する
        final isEqual = rssFeed == other;
        final sameHash = rssFeed.hashCode == other.hashCode;

        // Then: 等しく hashCode も一致する
        expect(isEqual, isTrue);
        expect(sameHash, isTrue);
      });

      test('should not be equal when only title differs', () {
        // Given: title だけが異なる RssFeed
        final other = RssFeed(
          title: 'other',
          link: 'https://tminasen.dev/',
          description: 'tminasen のブログ',
          lastBuildDate: DateTime.utc(2026, 11, 15, 9, 30),
          language: 'ja',
          imageUrl: 'https://tminasen.dev/icon.png',
        );

        // When: 比較する
        final isEqual = rssFeed == other;

        // Then: 等しくない
        expect(isEqual, isFalse);
      });
    });
  });

  group('AtomFeed', () {
    group('toJson', () {
      test('should return json with format atom when converted', () {
        // Given: AtomFeed
        // When: JSON に変換する
        final json = atomFeed.toJson();

        // Then: 判別子 atom 付きの JSON になる
        expect(json, equals(atomFeedJson));
      });
    });

    group('Feed.fromJson', () {
      test('should restore AtomFeed when format is atom', () {
        // Given: format が atom の JSON
        // When: Feed.fromJson を呼ぶ
        final feed = Feed.fromJson(atomFeedJson);

        // Then: AtomFeed として復元される
        expect(feed, isA<AtomFeed>());
        expect(feed, equals(atomFeed));
      });
    });

    group('common getters', () {
      test('should return title and link when accessed as Feed', () {
        // Given: Feed 型として保持した AtomFeed
        final Feed feed = atomFeed;

        // When: 共通項目を取得する
        final title = feed.title;
        final link = feed.link;

        // Then: AtomFeed の値が返る
        expect(title, equals('Example Atom'));
        expect(link, equals('https://example.com/'));
      });
    });
  });

  group('Feed equality', () {
    test('should not be equal when RssFeed is compared with AtomFeed', () {
      // Given: RssFeed と AtomFeed
      // When: 比較する
      final Feed rss = rssFeed;
      final Feed atom = atomFeed;
      final isEqual = rss == atom;

      // Then: 等しくない
      expect(isEqual, isFalse);
    });
  });

  group('Feed.fromJson errors', () {
    test('should throw FormatException when format is unknown', () {
      // Given: 未知の format を持つ JSON
      final json = <String, dynamic>{...rssFeedJson, 'format': 'json'};

      // When: Feed.fromJson を呼ぶ
      // Then: FormatException が送出される
      expect(() => Feed.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('should throw FormatException when format key is missing', () {
      // Given: format キーを欠く JSON
      final json = <String, dynamic>{...rssFeedJson}..remove('format');

      // When: Feed.fromJson を呼ぶ
      // Then: FormatException が送出される
      expect(() => Feed.fromJson(json), throwsA(isA<FormatException>()));
    });
  });

  group('null round trip', () {
    test('should restore RssFeed when all optional fields are null', () {
      // Given: 省略可能項目がすべて null の RssFeed
      const feed = RssFeed(
        title: 'tminasen.dev',
        link: 'https://tminasen.dev/',
        description: 'tminasen のブログ',
      );

      // When: JSON に変換して復元する
      final json = feed.toJson();
      final restored = Feed.fromJson(json);

      // Then: null がキー付きで出力され、元の値と等しい
      expect(
        json,
        equals(<String, dynamic>{
          'format': 'rss',
          'title': 'tminasen.dev',
          'link': 'https://tminasen.dev/',
          'description': 'tminasen のブログ',
          'lastBuildDate': null,
          'language': null,
          'imageUrl': null,
        }),
      );
      expect(restored, equals(feed));
    });

    test('should restore AtomFeed when all optional fields are null', () {
      // Given: 省略可能項目がすべて null の AtomFeed
      final feed = AtomFeed(
        id: 'tag:example.com,2026:feed',
        title: 'Example Atom',
        updated: DateTime.utc(2026, 11, 14),
      );

      // When: JSON に変換して復元する
      final json = feed.toJson();
      final restored = Feed.fromJson(json);

      // Then: link と subtitle が null で出力され、元の値と等しい
      expect(json['link'], isNull);
      expect(json['subtitle'], isNull);
      expect(json.containsKey('link'), isTrue);
      expect(json.containsKey('subtitle'), isTrue);
      expect(restored, equals(feed));
    });
  });
}
