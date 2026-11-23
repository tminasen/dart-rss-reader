import 'dart:math';

import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_app/src/article_view_helpers.dart';

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

final rssArticleB = RssArticle(
  title: 'styled-componentsからTailwindCSSに移行する際に困ったこと',
  link: 'https://tminasen.dev/blog/2',
  pubDate: DateTime(2025, 4, 14),
  enclosure: null,
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

final readItemB = ArticleItem(
  id: 'a-2',
  feedId: 'f-1',
  isRead: true,
  article: rssArticleB,
);

final unreadItemC = ArticleItem(
  id: 'a-3',
  feedId: 'f-1',
  isRead: false,
  article: atomArticleA,
);

void main() {
  group('formatArticleDate', () {
    // T6
    test('should format local pubDate as YYYY/MM/DD for RssArticle', () {
      // Given: pubDate が 2026-04-14 の rssArticleA

      // When: formatArticleDate を呼ぶ
      final formatted = formatArticleDate(rssArticleA);

      // Then: '2026/04/14' が返る
      expect(formatted, equals('2026/04/14'));
    });

    // T7
    test(
      'should convert UTC pubDate to local time and zero-pad month and day',
      () {
        // Given: UTC の pubDate
        final utc = DateTime.utc(2026, 1, 5, 0, 0);
        final local = utc.toLocal();
        final article = RssArticle(pubDate: utc);
        String two(int n) => n.toString().padLeft(2, '0');
        final expected =
            '${local.year.toString().padLeft(4, '0')}/${two(local.month)}/${two(local.day)}';

        // When: formatArticleDate を呼ぶ
        final formatted = formatArticleDate(article);

        // Then: ローカル時刻の YYYY/MM/DD（1桁月日はゼロ埋め）が返る
        expect(formatted, equals(expected));
      },
    );

    // T8
    test(
      'should prefer published over updated and fall back to updated for AtomArticle',
      () {
        // Given: published ありの atomArticleA と published が null の AtomArticle
        final withoutPublished = AtomArticle(
          id: 'atom-2',
          title: 'Atom記事2',
          published: null,
          updated: DateTime(2026, 2, 9),
        );

        // When: formatArticleDate を呼ぶ
        final result1 = formatArticleDate(atomArticleA);
        final result2 = formatArticleDate(withoutPublished);

        // Then: published 優先・null 時は updated が YYYY/MM/DD で返る
        expect(result1, equals('2026/01/05'));
        expect(result2, equals('2026/02/09'));
      },
    );

    // T9
    test('should return null when RssArticle pubDate is null', () {
      // Given: pubDate が null の RssArticle
      const article = RssArticle(title: '日付なし', pubDate: null);

      // When: formatArticleDate を呼ぶ
      final formatted = formatArticleDate(article);

      // Then: null が返る
      expect(formatted, isNull);
    });
  });

  group('extractThumbnailUrl', () {
    // T10
    test('should extract URL from RssArticle image/png enclosure', () {
      // Given: image/png の enclosure を持つ rssArticleA

      // When: extractThumbnailUrl を呼ぶ
      final url = extractThumbnailUrl(rssArticleA);

      // Then: enclosure の URL が返る
      expect(url, equals('https://tminasen.dev/images/1.png'));
    });

    // T11
    test(
      'should extract URL when enclosure type is mixed-case IMAGE/JPEG and http URL',
      () {
        // Given: type が大文字混在 IMAGE/JPEG で http URL の enclosure
        const article = RssArticle(
          enclosure: RssEnclosure(
            url: 'http://example.com/a.jpg',
            length: 100,
            type: 'IMAGE/JPEG',
          ),
        );

        // When: extractThumbnailUrl を呼ぶ
        final url = extractThumbnailUrl(article);

        // Then: 'http://example.com/a.jpg' が返る
        expect(url, equals('http://example.com/a.jpg'));
      },
    );

    // T12
    test('should return null when enclosure type is non-image', () {
      // Given: type が audio/mpeg の enclosure を持つ RssArticle
      const article = RssArticle(
        enclosure: RssEnclosure(
          url: 'https://example.com/a.mp3',
          length: 100,
          type: 'audio/mpeg',
        ),
      );

      // When: extractThumbnailUrl を呼ぶ
      final url = extractThumbnailUrl(article);

      // Then: null が返る
      expect(url, isNull);
    });

    // T13
    test(
      'should return null when enclosure url uses non-http/https scheme',
      () {
        // Given: javascript: スキームの URL を持つ画像 enclosure
        const article = RssArticle(
          enclosure: RssEnclosure(
            url: 'javascript:alert(1)',
            length: 0,
            type: 'image/png',
          ),
        );

        // When: extractThumbnailUrl を呼ぶ
        final url = extractThumbnailUrl(article);

        // Then: null が返る
        expect(url, isNull);
      },
    );

    // T14
    test(
      'should return null when RssArticle enclosure is null or article is AtomArticle',
      () {
        // Given: enclosure が null の rssArticleB と atomArticleA

        // When: extractThumbnailUrl を呼ぶ
        final resultRss = extractThumbnailUrl(rssArticleB);
        final resultAtom = extractThumbnailUrl(atomArticleA);

        // Then: どちらも null が返る
        expect(resultRss, isNull);
        expect(resultAtom, isNull);
      },
    );
  });

  group('safeArticleLink', () {
    // T15
    test('should return http and https article links as-is', () {
      // Given: https リンクを持つ rssArticleA と http リンクの RssArticle
      const httpArticle = RssArticle(link: 'http://example.com/1');

      // When: safeArticleLink を呼ぶ
      final linkHttps = safeArticleLink(rssArticleA);
      final linkHttp = safeArticleLink(httpArticle);

      // Then: それぞれの URL がそのまま返る
      expect(linkHttps, equals('https://tminasen.dev/blog/1'));
      expect(linkHttp, equals('http://example.com/1'));
    });

    // T16
    test('should return null for null, empty, or javascript: scheme links', () {
      // Given: link が null、空文字、javascript: スキームの各 RssArticle
      const nullLink = RssArticle(link: null);
      const emptyLink = RssArticle(link: '');
      const jsLink = RssArticle(link: 'javascript:alert(1)');

      // When: safeArticleLink を呼ぶ
      // Then: すべて null が返る
      expect(safeArticleLink(nullLink), isNull);
      expect(safeArticleLink(emptyLink), isNull);
      expect(safeArticleLink(jsLink), isNull);
    });

    // T55
    test('should return null when article link has empty host', () {
      // Given: スキームが http/https だがホストが空の link を持つ各 RssArticle
      const emptyAuthorityLink = RssArticle(link: 'https:///feed.xml');
      const schemeOnlyLink = RssArticle(link: 'https:');

      // When: safeArticleLink を呼ぶ
      // Then: どちらも null が返る
      expect(safeArticleLink(emptyAuthorityLink), isNull);
      expect(safeArticleLink(schemeOnlyLink), isNull);
    });
  });

  group('displayArticleTitle', () {
    // T17
    test('should return 無題の記事 when title is null or whitespace only', () {
      // Given: title が null、空白のみ、および通常の rssArticleA
      const nullTitle = RssArticle(title: null);
      const blankTitle = RssArticle(title: '   ');

      // When: displayArticleTitle を呼ぶ
      // Then: null / 空白のみは「無題の記事」、通常タイトルは元タイトルが返る
      expect(displayArticleTitle(nullTitle), equals('無題の記事'));
      expect(displayArticleTitle(blankTitle), equals('無題の記事'));
      expect(
        displayArticleTitle(rssArticleA),
        equals('Angularを使ってボードゲームの得点計算ツールを作った話'),
      );
    });
  });

  group('filterArticles and countUnread', () {
    // T18
    test(
      'should filter all/unread preserving order and count unread items',
      () {
        // Given: 未読2件・既読1件を含む一覧
        final items = [unreadItemA, readItemB, unreadItemC];

        // When: filterArticles と countUnread を呼ぶ
        final allResult = filterArticles(items, ArticleFilter.all);
        final unreadResult = filterArticles(items, ArticleFilter.unread);
        final unreadCount = countUnread(items);

        // Then: all は全件、unread は未読のみ元順序で返り、countUnread は 2
        expect(allResult, equals([unreadItemA, readItemB, unreadItemC]));
        expect(unreadResult, equals([unreadItemA, unreadItemC]));
        expect(unreadCount, equals(2));
      },
    );

    group('P2: filter and unread count invariants', () {
      List<ArticleItem> buildItems(int length, bool Function(int i) isReadAt) {
        return [
          for (var i = 0; i < length; i++)
            ArticleItem(
              id: 'item-$i',
              feedId: 'f-1',
              isRead: isReadAt(i),
              article: RssArticle(title: '記事$i'),
            ),
        ];
      }

      final random = Random(42);
      final patterns = <String, bool Function(int)>{
        'allUnread': (_) => false,
        'allRead': (_) => true,
        'alternating': (i) => i.isOdd,
        'firstHalfUnread': (i) => i >= 5,
      };

      for (var length = 0; length <= 20; length++) {
        for (final entry in patterns.entries) {
          test(
            'should satisfy filter and count invariants when length=$length pattern=${entry.key}',
            () {
              // Given: 長さ length・パターン entry.key の記事リスト
              final list = buildItems(length, entry.value);
              final originalSnapshot = List<ArticleItem>.of(list);

              // When: all/unread フィルタと countUnread を適用する
              final allFiltered = filterArticles(list, ArticleFilter.all);
              final unreadFiltered = filterArticles(list, ArticleFilter.unread);
              final unreadCount = countUnread(list);

              // Then: 件数整合性・不変性・未読条件・相対順序保持を満たす
              expect(allFiltered, equals(list));
              expect(unreadFiltered.length, equals(unreadCount));
              expect(unreadCount, inInclusiveRange(0, list.length));
              expect(unreadFiltered.every((item) => !item.isRead), isTrue);
              final expectedUnreadIds = [
                for (final item in list)
                  if (!item.isRead) item.id,
              ];
              expect(
                unreadFiltered.map((e) => e.id).toList(),
                equals(expectedUnreadIds),
              );
              expect(list, equals(originalSnapshot));
            },
          );
        }

        // ランダム混在パターン（固定シード）
        final randomFlags = [
          for (var i = 0; i < length; i++) random.nextBool(),
        ];
        test(
          'should satisfy filter and count invariants when length=$length pattern=random',
          () {
            // Given: ランダムに既読/未読を混在させた記事リスト
            final list = buildItems(length, (i) => randomFlags[i]);

            // When: all/unread フィルタと countUnread を適用する
            final allFiltered = filterArticles(list, ArticleFilter.all);
            final unreadFiltered = filterArticles(list, ArticleFilter.unread);
            final unreadCount = countUnread(list);

            // Then: 不変条件を満たす
            expect(allFiltered, equals(list));
            expect(unreadFiltered.length, equals(unreadCount));
            expect(unreadCount, inInclusiveRange(0, list.length));
            expect(unreadFiltered.every((item) => !item.isRead), isTrue);
            expect(
              unreadFiltered.map((e) => e.id).toList(),
              equals([
                for (final item in list)
                  if (!item.isRead) item.id,
              ]),
            );
          },
        );
      }
    });
  });

  group('prependIfAbsent', () {
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

    test('should prepend item when id is not in list', () {
      // Given: newItem を含まない [unreadItemA, readItemB]
      final list = [unreadItemA, readItemB];

      // When: prependIfAbsent を呼ぶ
      final result = prependIfAbsent(list, newItem);

      // Then: newItem が先頭に加わったリストが返る
      expect(result, equals([newItem, unreadItemA, readItemB]));
    });

    test('should return unchanged list when same id already exists', () {
      // Given: unreadItemA と同じ id で isRead: true の項目
      final list = [unreadItemA, readItemB];
      final duplicate = ArticleItem(
        id: unreadItemA.id,
        feedId: unreadItemA.feedId,
        isRead: true,
        article: unreadItemA.article,
      );

      // When: prependIfAbsent を呼ぶ
      final result = prependIfAbsent(list, duplicate);

      // Then: 既存の unreadItemA を置き換えず、リストは変わらない
      expect(result, equals([unreadItemA, readItemB]));
    });

    group('invariants', () {
      // 入力ドメイン: list は id a-1〜a-5 から重複なく選んだ 0〜5 件、
      // item は id a-1〜a-6 のいずれか。固定シードで list の選び方を変えた複数ケースを使う。
      ArticleItem itemWithId(int n) => ArticleItem(
        id: 'a-$n',
        feedId: 'f-1',
        isRead: n.isEven,
        article: rssArticleA,
      );

      final random = Random(42);
      final cases = <(List<ArticleItem>, ArticleItem)>[];
      for (var length = 0; length <= 5; length++) {
        for (var itemId = 1; itemId <= 6; itemId++) {
          final ids = [1, 2, 3, 4, 5]..shuffle(random);
          cases.add((
            [for (final n in ids.take(length)) itemWithId(n)],
            itemWithId(itemId),
          ));
        }
      }

      for (final (index, (list, item)) in cases.indexed) {
        test('should be idempotent and keep ids unique for case $index', () {
          // Given: 入力ドメインから作った list と item

          // When: 1回と2回続けて prependIfAbsent を適用する
          final once = prependIfAbsent(list, item);
          final twice = prependIfAbsent(once, item);

          // Then: 2回適用しても結果は同じで、id は重複せず、件数は高々1件増える
          expect(twice, equals(once));
          expect(once.map((e) => e.id).toSet().length, equals(once.length));
          expect(once.length, inInclusiveRange(list.length, list.length + 1));
        });
      }
    });
  });
}
