import 'package:shared/shared.dart';
import 'package:test/test.dart';

const enclosure = RssEnclosure(
  url: 'https://tminasen.dev/audio/hello.mp3',
  length: 12345,
  type: 'audio/mpeg',
);

final rssArticle = RssArticle(
  title: 'Hello',
  link: 'https://tminasen.dev/posts/hello',
  guid: 'https://tminasen.dev/posts/hello',
  pubDate: DateTime.utc(2026, 11, 10, 12),
  description: '<p>本文</p>',
  enclosure: enclosure,
);

final rssArticleJson = <String, dynamic>{
  'format': 'rss',
  'title': 'Hello',
  'link': 'https://tminasen.dev/posts/hello',
  'guid': 'https://tminasen.dev/posts/hello',
  'pubDate': '2026-11-10T12:00:00.000Z',
  'description': '<p>本文</p>',
  'enclosure': {
    'url': 'https://tminasen.dev/audio/hello.mp3',
    'length': 12345,
    'type': 'audio/mpeg',
  },
};

final atomArticle = AtomArticle(
  id: 'tag:example.com,2026:entry-1',
  title: 'Atom entry',
  updated: DateTime.utc(2026, 11, 13),
  link: 'https://example.com/entry-1',
  published: DateTime.utc(2026, 11, 12),
  summary: '要約',
);

final atomArticleJson = <String, dynamic>{
  'format': 'atom',
  'id': 'tag:example.com,2026:entry-1',
  'title': 'Atom entry',
  'updated': '2026-11-13T00:00:00.000Z',
  'link': 'https://example.com/entry-1',
  'published': '2026-11-12T00:00:00.000Z',
  'summary': '要約',
};

void main() {
  group('RssArticle', () {
    group('toJson', () {
      test('should return json with nested enclosure map when converted', () {
        // Given: enclosure を持つ RssArticle
        // When: JSON に変換する
        final json = rssArticle.toJson();

        // Then: 判別子 rss 付きで enclosure が入れ子の Map になる
        expect(json, equals(rssArticleJson));
        expect(json['enclosure'], isA<Map<dynamic, dynamic>>());
      });
    });

    group('Article.fromJson', () {
      test('should restore RssArticle when format is rss', () {
        // Given: format が rss の JSON
        // When: Article.fromJson を呼ぶ
        final article = Article.fromJson(rssArticleJson);

        // Then: RssArticle として復元される
        expect(article, isA<RssArticle>());
        expect(article, equals(rssArticle));
      });
    });

    group('common getters', () {
      test('should return title and link when accessed as Article', () {
        // Given: Article 型として保持した RssArticle
        final Article article = rssArticle;

        // When: 共通項目を取得する
        final title = article.title;
        final link = article.link;

        // Then: RssArticle の値が返る
        expect(title, equals('Hello'));
        expect(link, equals('https://tminasen.dev/posts/hello'));
      });
    });

    group('equality', () {
      test('should be equal when enclosure has the same values', () {
        // Given: 同じ値の enclosure を新規生成した RssArticle
        final other = RssArticle(
          title: 'Hello',
          link: 'https://tminasen.dev/posts/hello',
          guid: 'https://tminasen.dev/posts/hello',
          pubDate: DateTime.utc(2026, 11, 10, 12),
          description: '<p>本文</p>',
          enclosure: RssEnclosure(
            url: 'https://tminasen.dev/audio/hello.mp3',
            length: 12345,
            type: 'audio/mpeg',
          ),
        );

        // When: 比較する
        final isEqual = rssArticle == other;
        final sameHash = rssArticle.hashCode == other.hashCode;

        // Then: 等しく hashCode も一致する
        expect(isEqual, isTrue);
        expect(sameHash, isTrue);
      });

      test('should not be equal when only enclosure length differs', () {
        // Given: enclosure の length だけが異なる RssArticle
        final other = RssArticle(
          title: 'Hello',
          link: 'https://tminasen.dev/posts/hello',
          guid: 'https://tminasen.dev/posts/hello',
          pubDate: DateTime.utc(2026, 11, 10, 12),
          description: '<p>本文</p>',
          enclosure: RssEnclosure(
            url: 'https://tminasen.dev/audio/hello.mp3',
            length: 12346,
            type: 'audio/mpeg',
          ),
        );

        // When: 比較する
        final isEqual = rssArticle == other;

        // Then: 等しくない
        expect(isEqual, isFalse);
      });
    });
  });

  group('AtomArticle', () {
    group('toJson', () {
      test('should return json with format atom when converted', () {
        // Given: AtomArticle
        // When: JSON に変換する
        final json = atomArticle.toJson();

        // Then: 判別子 atom 付きの JSON になる
        expect(json, equals(atomArticleJson));
      });
    });

    group('Article.fromJson', () {
      test('should restore AtomArticle when format is atom', () {
        // Given: format が atom の JSON
        // When: Article.fromJson を呼ぶ
        final article = Article.fromJson(atomArticleJson);

        // Then: AtomArticle として復元される
        expect(article, isA<AtomArticle>());
        expect(article, equals(atomArticle));
      });
    });

    group('common getters', () {
      test('should return title and link when accessed as Article', () {
        // Given: Article 型として保持した AtomArticle
        final Article article = atomArticle;

        // When: 共通項目を取得する
        final title = article.title;
        final link = article.link;

        // Then: AtomArticle の値が返る
        expect(title, equals('Atom entry'));
        expect(link, equals('https://example.com/entry-1'));
      });
    });
  });

  group('Article.fromJson errors', () {
    test('should throw FormatException when format is unknown', () {
      // Given: 未知の format を持つ JSON
      final json = <String, dynamic>{...rssArticleJson, 'format': 'json'};

      // When: Article.fromJson を呼ぶ
      // Then: FormatException が送出される
      expect(() => Article.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('should throw FormatException when format key is missing', () {
      // Given: format キーを欠く JSON
      final json = <String, dynamic>{...rssArticleJson}..remove('format');

      // When: Article.fromJson を呼ぶ
      // Then: FormatException が送出される
      expect(() => Article.fromJson(json), throwsA(isA<FormatException>()));
    });
  });

  group('null round trip', () {
    test('should restore RssArticle when all fields are null', () {
      // Given: 全項目 null の RssArticle
      const article = RssArticle();

      // When: JSON に変換して復元する
      final json = article.toJson();
      final restored = Article.fromJson(json);

      // Then: null がキー付きで出力され、元の値と等しい
      expect(
        json,
        equals(<String, dynamic>{
          'format': 'rss',
          'title': null,
          'link': null,
          'guid': null,
          'pubDate': null,
          'description': null,
          'enclosure': null,
        }),
      );
      expect(restored, equals(const RssArticle()));
    });

    test('should restore AtomArticle when all optional fields are null', () {
      // Given: 省略可能項目がすべて null の AtomArticle
      final article = AtomArticle(
        id: 'tag:example.com,2026:entry-1',
        title: 'Atom entry',
        updated: DateTime.utc(2026, 11, 13),
      );

      // When: JSON に変換して復元する
      final json = article.toJson();
      final restored = Article.fromJson(json);

      // Then: link / published / summary が null で出力され、元の値と等しい
      for (final key in ['link', 'published', 'summary']) {
        expect(json.containsKey(key), isTrue);
        expect(json[key], isNull);
      }
      expect(restored, equals(article));
    });
  });
}
