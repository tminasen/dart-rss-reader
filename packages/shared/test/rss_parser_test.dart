import 'dart:io';

import 'package:shared/shared.dart';
import 'package:test/test.dart';

const minimalChannel =
    '<title>T</title><link>https://example.com</link><description>D</description>';

String rssOf(String channelInner) =>
    '<?xml version="1.0" encoding="utf-8"?><rss version="2.0"><channel>$channelInner</channel></rss>';

String itemOf(String itemInner) =>
    rssOf('$minimalChannel<item>$itemInner</item>');

final sampleXml = File('test/fixtures/tminasen_feed.xml').readAsStringSync();

const firstItemDescription =
    '''path: "/blog/040a4af3-391e-4470-912e-4deca2cdcb2c",
  date: "2026/04/14",
  title: "Angularを使ってボードゲームの得点計算ツールを作った話",
  tag: ["Angu…''';

void main() {
  group('parseRss', () {
    group('malformed xml', () {
      final cases = <String, String>{
        '閉じタグのない XML': '<rss version="2.0"><channel>',
        '開始・終了タグが対応しない XML': '<rss version="2.0"><channel></rss>',
        '空文字': '',
      };
      for (final entry in cases.entries) {
        test(
          'should throw MalformedXmlException when input is ${entry.key}',
          () {
            // Given: 整形式でない XML
            // When: パースする
            // Then: MalformedXmlException（RssParseException のサブタイプ）
            expect(
              () => parseRss(entry.value),
              throwsA(
                allOf(isA<MalformedXmlException>(), isA<RssParseException>()),
              ),
            );
          },
        );
      }
    });

    group('not rss', () {
      final cases = <String, String>{
        'ルートが rss でない（Atom）':
            '<feed xmlns="http://www.w3.org/2005/Atom"><title>A</title></feed>',
        'channel のない rss': '<rss version="2.0"></rss>',
      };
      for (final entry in cases.entries) {
        test('should throw NotRssFeedException when ${entry.key}', () {
          // Given: RSS として成立しない文書
          // When: パースする
          // Then: NotRssFeedException（RssParseException のサブタイプ）
          expect(
            () => parseRss(entry.value),
            throwsA(
              allOf(isA<NotRssFeedException>(), isA<RssParseException>()),
            ),
          );
        });
      }
    });

    group('missing required element', () {
      final cases = <String, String>{
        'title': rssOf(
          '<link>https://example.com</link><description>D</description>',
        ),
        'link': rssOf('<title>T</title><description>D</description>'),
        'description': rssOf(
          '<title>T</title><link>https://example.com</link>',
        ),
      };
      for (final entry in cases.entries) {
        test(
          'should throw MissingRequiredElementException when ${entry.key} is missing',
          () {
            // Given: 必須要素が1つ欠けた channel
            // When: パースする
            // Then: 欠損要素名を持つ MissingRequiredElementException
            expect(
              () => parseRss(entry.value),
              throwsA(
                allOf(
                  isA<RssParseException>(),
                  isA<MissingRequiredElementException>().having(
                    (e) => e.elementName,
                    'elementName',
                    entry.key,
                  ),
                ),
              ),
            );
          },
        );
      }
    });

    group('channel', () {
      test('should leave optional fields null when only required exist', () {
        // Given: 必須要素だけの channel
        final xml = rssOf(minimalChannel);

        // When: パースする
        final result = parseRss(xml);

        // Then: 任意項目は null、記事は空
        expect(
          result.feed,
          equals(
            const RssFeed(
              title: 'T',
              link: 'https://example.com',
              description: 'D',
            ),
          ),
        );
        expect(result.articles, isEmpty);
      });

      test('should convert lastBuildDate to utc when it has numeric offset', () {
        // Given: 数値オフセット付きの lastBuildDate
        final xml = rssOf(
          '$minimalChannel<lastBuildDate>Mon, 13 Apr 2026 16:17:13 +0900</lastBuildDate>',
        );

        // When: パースする
        final feed = parseRss(xml).feed;

        // Then: UTC に変換される
        expect(
          feed.lastBuildDate,
          equals(DateTime.utc(2026, 4, 13, 7, 17, 13)),
        );
      });

      test('should not use image title and link when reading channel values', () {
        // Given: channel の title より前に image（title/link/url）がある
        final xml = rssOf(
          '<image><title>IMG</title><url>https://example.com/i.png</url><link>https://example.com/img</link></image>'
          '<title>T</title><link>https://example.com</link><description>D</description>',
        );

        // When: パースする
        final feed = parseRss(xml).feed;

        // Then: channel 直下の値が使われ、imageUrl は image の url
        expect(feed.title, equals('T'));
        expect(feed.link, equals('https://example.com'));
        expect(feed.imageUrl, equals('https://example.com/i.png'));
      });

      test('should not treat atom:link as link when namespaced element exists', () {
        // Given: link より前に atom:link がある
        const xml =
            '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom"><channel>'
            '<title>T</title>'
            '<atom:link href="https://example.com/feed.xml" rel="self" type="application/rss+xml"/>'
            '<link>https://example.com</link><description>D</description>'
            '</channel></rss>';

        // When: パースする
        final feed = parseRss(xml).feed;

        // Then: 通常の link 要素が使われる
        expect(feed.link, equals('https://example.com'));
      });

      test('should return null imageUrl when image has no url', () {
        // Given: url のない image
        final xml = rssOf(
          '$minimalChannel<image><title>IMG</title><link>https://example.com</link></image>',
        );

        // When: パースする
        final feed = parseRss(xml).feed;

        // Then: imageUrl は null
        expect(feed.imageUrl, isNull);
      });

      test('should return null lastBuildDate when it is not a date', () {
        // Given: 解釈できない lastBuildDate
        final xml = rssOf(
          '$minimalChannel<lastBuildDate>yesterday</lastBuildDate>',
        );

        // When: パースする
        final feed = parseRss(xml).feed;

        // Then: lastBuildDate は null で feed は得られる
        expect(
          feed,
          equals(
            const RssFeed(
              title: 'T',
              link: 'https://example.com',
              description: 'D',
            ),
          ),
        );
      });
    });

    group('item', () {
      test('should return RssArticle with all null when item is empty', () {
        // Given: 子要素のない item
        final xml = rssOf('$minimalChannel<item></item>');

        // When: パースする
        final articles = parseRss(xml).articles;

        // Then: 全項目 null の RssArticle になる
        expect(articles, equals([const RssArticle()]));
      });

      test('should restore entity when title is plain text', () {
        // Given: 実体参照を含む title
        final xml = itemOf('<title>A &amp; B</title>');

        // When: パースする
        final article = parseRss(xml).articles.single;

        // Then: 実体参照が復元される
        expect(article.title, equals('A & B'));
      });

      test('should keep html as is when description is CDATA', () {
        // Given: CDATA 内に HTML を含む description
        final xml = itemOf('<description><![CDATA[<p>本文</p>]]></description>');

        // When: パースする
        final article = parseRss(xml).articles.single;

        // Then: HTML がそのまま description になる
        expect(article.description, equals('<p>本文</p>'));
      });

      test('should use text as guid when guid has attributes', () {
        // Given: 属性付きの guid
        final xml = itemOf('<guid isPermaLink="false">abc-123</guid>');

        // When: パースする
        final article = parseRss(xml).articles.single;

        // Then: テキストが guid になる
        expect(article.guid, equals('abc-123'));
      });

      test('should return null pubDate when it is not a date', () {
        // Given: 解釈できない pubDate
        final xml = itemOf('<title>A</title><pubDate>not a date</pubDate>');

        // When: パースする
        final article = parseRss(xml).articles.single;

        // Then: pubDate は null で記事は取り込まれる
        expect(article, equals(const RssArticle(title: 'A')));
      });
    });

    group('text normalization', () {
      test('should trim surrounding whitespace when text has line breaks', () {
        // Given: 前後に改行・空白がある title
        final xml = rssOf(
          '<title>\n    T\n  </title><link>https://example.com</link><description>D</description>',
        );

        // When: パースする
        final feed = parseRss(xml).feed;

        // Then: 前後の空白が除かれる
        expect(feed.title, equals('T'));
      });

      test('should return empty string when element is empty', () {
        // Given: 中身が空の language
        final xml = rssOf('$minimalChannel<language></language>');

        // When: パースする
        final feed = parseRss(xml).feed;

        // Then: null ではなく空文字になる
        expect(feed.language, equals(''));
      });
    });

    group('enclosure', () {
      test('should convert enclosure when length is a positive integer', () {
        // Given: 属性がそろった enclosure
        final xml = itemOf(
          '<title>A</title><enclosure url="https://example.com/a.mp3" length="12345" type="audio/mpeg"/>',
        );

        // When: パースする
        final article = parseRss(xml).articles.single;

        // Then: RssEnclosure に変換される
        expect(
          article.enclosure,
          equals(
            const RssEnclosure(
              url: 'https://example.com/a.mp3',
              length: 12345,
              type: 'audio/mpeg',
            ),
          ),
        );
      });

      final invalidCases = <String, String>{
        'url 欠損': 'length="1" type="image/png"',
        'length 欠損': 'url="https://example.com/a.png" type="image/png"',
        'type 欠損': 'url="https://example.com/a.png" length="1"',
        'length 非数':
            'url="https://example.com/a.png" length="abc" type="image/png"',
        'length 小数':
            'url="https://example.com/a.png" length="12.5" type="image/png"',
      };
      for (final entry in invalidCases.entries) {
        test('should return null enclosure when ${entry.key}', () {
          // Given: 不正な enclosure を持つ item
          final xml = itemOf('<title>A</title><enclosure ${entry.value}/>');

          // When: パースする
          final article = parseRss(xml).articles.single;

          // Then: enclosure だけ null で記事は取り込まれる
          expect(article, equals(const RssArticle(title: 'A')));
        });
      }
    });

    group('sample feed', () {
      test('should return RssFeed when parsing channel of sample xml', () {
        // Given: 対象フィードのサンプル XML
        // When: パースする
        final feed = parseRss(sampleXml).feed;

        // Then: channel の内容が RssFeed になる
        expect(
          feed,
          equals(
            RssFeed(
              title: '水無瀬のプログラミング日記feed',
              link: 'https://tminasen.dev',
              description: '水無瀬のプログラミング日記のfeed',
              lastBuildDate: DateTime.utc(2026, 4, 13, 16, 17, 13),
              language: 'ja',
              imageUrl: 'https://tminasen.dev/images/ogp.png',
            ),
          ),
        );
      });

      test('should return 10 articles in document order when sample xml', () {
        // Given: 対象フィードのサンプル XML
        // When: パースする
        final articles = parseRss(sampleXml).articles;

        // Then: item 10件が文書順で得られる
        expect(articles, hasLength(10));
        expect(articles.first.title, equals('Angularを使ってボードゲームの得点計算ツールを作った話'));
        expect(articles.last.title, equals('Next.js+linariaを試してみる'));
      });

      test('should return fully populated RssArticle for first item', () {
        // Given: 対象フィードのサンプル XML
        // When: パースする
        final article = parseRss(sampleXml).articles.first;

        // Then: 先頭 item の全項目が変換される
        expect(
          article,
          equals(
            RssArticle(
              title: 'Angularを使ってボードゲームの得点計算ツールを作った話',
              link:
                  'https://tminasen.dev/blog/040a4af3-391e-4470-912e-4deca2cdcb2c',
              guid:
                  'https://tminasen.dev/blog/040a4af3-391e-4470-912e-4deca2cdcb2c',
              pubDate: DateTime.utc(2026, 4, 14),
              description: firstItemDescription,
              enclosure: const RssEnclosure(
                url:
                    'https://tminasen.dev/images/article/040a4af3-391e-4470-912e-4deca2cdcb2c/ogp.png',
                length: 0,
                type: 'image/png',
              ),
            ),
          ),
        );
      });
    });

    group('truncated input invariant', () {
      test(
        'should return a result or throw RssParseException for any prefix',
        () {
          // Given: サンプル XML の先頭 n 文字（n = 0, 7, 14, ...）
          for (var n = 0; n < sampleXml.length; n += 7) {
            final prefix = sampleXml.substring(0, n);

            // When: パースする
            Object? thrown;
            try {
              parseRss(prefix);
            } catch (e) {
              thrown = e;
            }

            // Then: 値を返すか RssParseException のサブタイプだけを投げる
            expect(
              thrown,
              anyOf(isNull, isA<RssParseException>()),
              reason: 'n=$n',
            );
          }
        },
      );
    });
  });
}
