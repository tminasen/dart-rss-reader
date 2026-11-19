import 'package:server/src/repository/article_repository.dart';
import 'package:server/src/repository/repository_exception.dart';
import 'package:server/src/repository/stored_article.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// feed-a に rss(1)〜rss(3)、feed-b に rss(4) を保存する。保存結果を返す。
Future<List<StoredArticle>> _seedFour(ArticleRepository repo) async {
  final a = await repo.addAll('feed-a', [rss(1), rss(2), rss(3)]);
  final b = await repo.addAll('feed-b', [rss(4)]);
  return [...a, ...b];
}

/// feed-a に rss(1)〜rss([n]) を保存する。
Future<void> _seedFeedA(ArticleRepository repo, int n) async {
  await repo.addAll('feed-a', [for (var i = 1; i <= n; i++) rss(i)]);
}

/// [items] の全順列。
List<List<T>> _permutations<T>(List<T> items) {
  if (items.length <= 1) return [List.of(items)];
  return [
    for (var i = 0; i < items.length; i++)
      for (final rest in _permutations([
        ...items.sublist(0, i),
        ...items.sublist(i + 1),
      ]))
        [items[i], ...rest],
  ];
}

/// [ArticleRepository] の実装が満たすべき契約。
/// 各テストで [createRepository] を呼び、新しいリポジトリを使う。
/// feedId は購読リポジトリに登録せず、そのまま使う。
void articleRepositoryContract(
  Future<ArticleRepository> Function() createRepository,
) {
  group('ArticleRepository', () {
    group('addAll', () {
      // T16
      test(
        'should return unread stored articles in input order when saved',
        () async {
          // Given: 空のリポジトリ
          final repo = await createRepository();

          // When: 2件保存する
          final stored = await repo.addAll('feed-a', [rss(1), rss(2)]);

          // Then: 未読の StoredArticle が入力順に返る
          expect(stored, hasLength(2));
          expect(stored[0].article, equals(rss(1)));
          expect(stored[1].article, equals(rss(2)));
          expect(stored.every((s) => s.feedId == 'feed-a'), isTrue);
          expect(stored.every((s) => !s.isRead), isTrue);
          expect(stored[0].id, isNot(stored[1].id));
        },
      );

      // T18
      test('should save atom article when article is AtomArticle', () async {
        // Given: 空のリポジトリ
        final repo = await createRepository();

        // When: Atom 記事を保存し、ID で取得する
        final stored = await repo.addAll('feed-b', [atomArticle]);
        final found = await repo.findById(stored[0].id);

        // Then: 保存された記事が Atom 記事と等しく、取得結果も一致する
        expect(stored, hasLength(1));
        expect(stored[0].article, equals(atomArticle));
        expect(found, equals(stored[0]));
      });

      // T19
      test('should save nothing when articles is empty', () async {
        // Given: 空のリポジトリ
        final repo = await createRepository();

        // When: 空リストを渡す
        final stored = await repo.addAll('feed-a', []);
        final all = await repo.find();

        // Then: 何も保存されない
        expect(stored, isEmpty);
        expect(all, isEmpty);
      });
    });

    group('addAll deduplication', () {
      // T21
      test(
        'should not save article when guid is duplicated in same feed',
        () async {
          // Given: 保存済みの記事
          final repo = await createRepository();
          await repo.addAll('feed-a', [rss(1)]);

          // When: 同じ guid の記事を再保存する
          final stored = await repo.addAll('feed-a', [rss(1)]);
          final all = await repo.find(feedId: 'feed-a');

          // Then: 保存されず、件数は増えない
          expect(stored, isEmpty);
          expect(all, hasLength(1));
        },
      );

      // T22
      test('should judge duplicate by link when guid is absent', () async {
        // Given: guid がなく link だけを持つ保存済み記事
        final repo = await createRepository();
        const noGuid = RssArticle(
          title: 'guid なし',
          link: 'https://tminasen.dev/posts/nog',
        );
        await repo.addAll('feed-a', [noGuid]);

        // When: 同じ記事を再保存する
        final stored = await repo.addAll('feed-a', [noGuid]);
        final all = await repo.find();

        // Then: 保存されず、件数は増えない
        expect(stored, isEmpty);
        expect(all, hasLength(1));
      });

      // T23
      test(
        'should save article when guid differs even if link is same',
        () async {
          // Given: 保存済みの記事
          final repo = await createRepository();
          await repo.addAll('feed-a', [rss(1)]);

          // When: link は同じで guid が異なる記事を保存する
          final stored = await repo.addAll('feed-a', [
            const RssArticle(
              title: '記事1 改',
              link: 'https://tminasen.dev/posts/1',
              guid: 'post-1-v2',
            ),
          ]);
          final all = await repo.find();

          // Then: 別記事として保存される
          expect(stored, hasLength(1));
          expect(all, hasLength(2));
        },
      );

      // T24
      test(
        'should save article when same guid exists in another feed',
        () async {
          // Given: feed-a に保存済みの記事
          final repo = await createRepository();
          await repo.addAll('feed-a', [rss(1)]);

          // When: 別フィードに同じ guid の記事を保存する
          final stored = await repo.addAll('feed-b', [rss(1)]);
          final all = await repo.find();

          // Then: 保存される
          expect(stored, hasLength(1));
          expect(stored[0].feedId, 'feed-b');
          expect(all, hasLength(2));
        },
      );

      // T25
      test('should not save article when atom id is duplicated', () async {
        // Given: 保存済みの Atom 記事
        final repo = await createRepository();
        await repo.addAll('feed-b', [atomArticle]);

        // When: 同じ Atom 記事を再保存する
        final stored = await repo.addAll('feed-b', [atomArticle]);
        final all = await repo.find();

        // Then: 保存されず、件数は増えない
        expect(stored, isEmpty);
        expect(all, hasLength(1));
      });

      // T26
      test(
        'should keep first article when duplicates are in same call',
        () async {
          // Given: 空のリポジトリ
          final repo = await createRepository();

          // When: 同じ guid の記事を同時に渡す
          final stored = await repo.addAll('feed-a', [
            rss(1),
            const RssArticle(title: '重複', guid: 'post-1'),
          ]);

          // Then: 先に出てきたものだけが保存される
          expect(stored, hasLength(1));
          expect(stored[0].article, equals(rss(1)));
        },
      );

      // T27
      test(
        'should not save article when neither guid nor link exists',
        () async {
          // Given: 空のリポジトリ
          final repo = await createRepository();

          // When: guid も link もない記事を保存する
          final stored = await repo.addAll('feed-a', [
            const RssArticle(title: 'キーなし', description: '本文'),
          ]);
          final all = await repo.find();

          // Then: 保存されない
          expect(stored, isEmpty);
          expect(all, isEmpty);
        },
      );

      // T48
      test('should fall back to link when guid is empty', () async {
        // Given: guid が空文字で link が異なる2件の記事
        final repo = await createRepository();
        const a = RssArticle(
          title: '空guid1',
          link: 'https://tminasen.dev/posts/e1',
          guid: '',
        );
        const b = RssArticle(
          title: '空guid2',
          link: 'https://tminasen.dev/posts/e2',
          guid: '',
        );

        // When: 2件を同時に保存する
        final stored = await repo.addAll('feed-a', [a, b]);

        // Then: link で区別され、両方保存される
        expect([for (final s in stored) s.article], equals([a, b]));
      });

      // T49
      test('should not save article when guid and link are empty', () async {
        // Given: 空のリポジトリ
        final repo = await createRepository();

        // When: guid も link も空文字の記事を保存する
        final stored = await repo.addAll('feed-a', [
          const RssArticle(title: '空キー', guid: '', link: ''),
        ]);
        final all = await repo.find();

        // Then: 保存されない
        expect(stored, isEmpty);
        expect(all, isEmpty);
      });

      // T28
      test(
        'should keep read state when already read article is saved again',
        () async {
          // Given: 既読にした保存済みの記事
          final repo = await createRepository();
          final stored = await repo.addAll('feed-a', [rss(1)]);
          await repo.setRead(stored[0].id, isRead: true);

          // When: 同じ記事を再保存する
          final again = await repo.addAll('feed-a', [rss(1)]);
          final found = await repo.findById(stored[0].id);

          // Then: 何も追加されず、既読のまま
          expect(again, isEmpty);
          expect(found?.isRead, isTrue);
        },
      );

      // P3
      for (var n = 0; n <= 5; n++) {
        test(
          'should be idempotent when same $n articles are saved twice',
          () async {
            // Given: n 件の記事
            final repo = await createRepository();
            final list = [for (var i = 1; i <= n; i++) rss(i)];
            await repo.addAll('feed-a', list);

            // When: 同じリストをもう一度保存する
            final second = await repo.addAll('feed-a', list);
            final all = await repo.find();

            // Then: 2回目は何も追加されず、件数は n のまま
            expect(second, isEmpty);
            expect(all, hasLength(n));
          },
        );
      }
    });

    group('find', () {
      // T29
      test('should return empty list when repository is empty', () async {
        // Given: 空のリポジトリ
        final repo = await createRepository();

        // When: 一覧を取得する
        final all = await repo.find();

        // Then: 空リスト
        expect(all, isEmpty);
      });

      // T30
      test('should return all articles newest first when no filter', () async {
        // Given: 2フィードに4件保存済み
        final repo = await createRepository();
        await _seedFour(repo);

        // When: 絞り込みなしで取得する
        final all = await repo.find();

        // Then: 新しい順に並ぶ
        expect(
          all.map((s) => s.article),
          equals([rss(4), rss(3), rss(2), rss(1)]),
        );
      });

      // T31
      test('should filter by feedId when feedId is given', () async {
        // Given: 2フィードに4件保存済み
        final repo = await createRepository();
        await _seedFour(repo);

        // When: feed-a で絞り込む
        final found = await repo.find(feedId: 'feed-a');

        // Then: feed-a の記事だけが新しい順に返る
        expect(found.map((s) => s.article), equals([rss(3), rss(2), rss(1)]));
      });

      // T32
      test(
        'should return only unread articles when unreadOnly is true',
        () async {
          // Given: 4件保存済みで、rss(3) が既読
          final repo = await createRepository();
          final seeded = await _seedFour(repo);
          await repo.setRead(seeded[2].id, isRead: true);

          // When: 未読だけで取得する
          final found = await repo.find(unreadOnly: true);

          // Then: rss(3) を除いた記事が新しい順に返る
          expect(found.map((s) => s.article), equals([rss(4), rss(2), rss(1)]));
        },
      );

      // T33
      test(
        'should combine feedId and unreadOnly when both are given',
        () async {
          // Given: 4件保存済みで、rss(3) が既読
          final repo = await createRepository();
          final seeded = await _seedFour(repo);
          await repo.setRead(seeded[2].id, isRead: true);

          // When: feed-a かつ未読だけで取得する
          final found = await repo.find(feedId: 'feed-a', unreadOnly: true);

          // Then: feed-a の未読だけが返る
          expect(found.map((s) => s.article), equals([rss(2), rss(1)]));
        },
      );

      // T34
      test('should put articles without date last in saved order', () async {
        // Given: 日時なしの記事2件と日時ありの記事1件
        final repo = await createRepository();
        const n1 = RssArticle(guid: 'nodate-1', title: '日付なし1');
        const n2 = RssArticle(guid: 'nodate-2', title: '日付なし2');
        await repo.addAll('feed-a', [n1, rss(1), n2]);

        // When: 一覧を取得する
        final all = await repo.find();

        // Then: 日時ありが先頭で、日時なしは保存順に続く
        expect(all.map((s) => s.article), equals([rss(1), n1, n2]));
      });

      // T35
      test(
        'should use published or else updated as base date for atom',
        () async {
          // Given: published あり/なしの Atom 記事と RSS 記事
          final repo = await createRepository();
          final e2 = AtomArticle(
            id: 'tag:example.com,2026:entry-2',
            title: 'Atom 記事2',
            updated: DateTime.utc(2026, 11, 12),
          );
          await repo.addAll('feed-b', [atomArticle, e2]);
          await repo.addAll('feed-a', [rss(10)]);

          // When: 一覧を取得する
          final all = await repo.find();

          // Then: updated(11/12) > rss(10)(11/10) > published(11/9) の順
          expect(all.map((s) => s.article), equals([e2, rss(10), atomArticle]));
        },
      );

      // P4
      var permutationNo = 0;
      for (final order in _permutations([1, 2, 3, 4, 5])) {
        permutationNo++;
        test('should sort newest first when saved in order $order '
            '(#$permutationNo)', () async {
          // Given: rss(1)〜rss(5) を order の順に1件ずつ保存する
          final repo = await createRepository();
          for (final n in order) {
            await repo.addAll('feed-a', [rss(n)]);
          }

          // When: 一覧を取得する
          final all = await repo.find();

          // Then: 保存順に関係なく基準日時が単調非増加になる
          final dates = [
            for (final s in all) (s.article as RssArticle).pubDate!,
          ];
          expect(dates, hasLength(5));
          for (var i = 1; i < dates.length; i++) {
            expect(dates[i].isAfter(dates[i - 1]), isFalse);
          }
        });
      }

      // T36
      test('should return first page when offset is 0', () async {
        // Given: 5件保存済み
        final repo = await createRepository();
        await _seedFeedA(repo, 5);

        // When: limit 2、offset 0 で取得する
        final page = await repo.find(limit: 2, offset: 0);

        // Then: 新しい順の先頭2件
        expect(page.map((s) => s.article), equals([rss(5), rss(4)]));
      });

      // T37
      test('should return second page when offset is 2', () async {
        // Given: 5件保存済み
        final repo = await createRepository();
        await _seedFeedA(repo, 5);

        // When: limit 2、offset 2 で取得する
        final page = await repo.find(limit: 2, offset: 2);

        // Then: 3〜4件目
        expect(page.map((s) => s.article), equals([rss(3), rss(2)]));
      });

      // T38
      test(
        'should return remaining articles when last page is partial',
        () async {
          // Given: 5件保存済み
          final repo = await createRepository();
          await _seedFeedA(repo, 5);

          // When: limit 2、offset 4 で取得する
          final page = await repo.find(limit: 2, offset: 4);

          // Then: 残りの1件だけ
          expect(page.map((s) => s.article), equals([rss(1)]));
        },
      );

      // T39
      test('should return empty list when offset equals count', () async {
        // Given: 5件保存済み
        final repo = await createRepository();
        await _seedFeedA(repo, 5);

        // When: limit 2、offset 5 で取得する
        final page = await repo.find(limit: 2, offset: 5);

        // Then: 空
        expect(page, isEmpty);
      });

      // T40
      test('should return one article when limit is 1', () async {
        // Given: 5件保存済み
        final repo = await createRepository();
        await _seedFeedA(repo, 5);

        // When: limit 1 で取得する
        final page = await repo.find(limit: 1);

        // Then: 最新の1件だけ
        expect(page.map((s) => s.article), equals([rss(5)]));
      });

      // T47
      test(
        'should not change stored articles when returned list is modified',
        () async {
          // Given: 5件保存済みで、取得した一覧
          final repo = await createRepository();
          await _seedFeedA(repo, 5);
          final list = await repo.find();

          // When: 返されたリストを変更する（変更不可リストなら例外は無視する）
          try {
            list.clear();
          } on UnsupportedError {
            // 変更不可リストを返す実装も許容する
          }
          final again = await repo.find();

          // Then: 保存内容は変わらない
          expect(again, hasLength(5));
        },
      );

      // P1
      for (var n = 0; n <= 6; n++) {
        test(
          'should return min(limit, remaining) articles when $n saved',
          () async {
            // Given: n 件保存済み
            final repo = await createRepository();
            await _seedFeedA(repo, n);

            for (var limit = 1; limit <= 7; limit++) {
              for (var offset = 0; offset <= 7; offset++) {
                // When: limit と offset を指定して取得する
                final page = await repo.find(limit: limit, offset: offset);

                // Then: 件数は min(limit, max(0, n - offset))
                final expected = [
                  limit,
                  n - offset < 0 ? 0 : n - offset,
                ].reduce((a, b) => a < b ? a : b);
                expect(
                  page,
                  hasLength(expected),
                  reason: 'n=$n limit=$limit offset=$offset',
                );
              }
            }
          },
        );
      }

      // T41
      test('should throw ArgumentError when limit is 0', () async {
        // Given: 5件保存済み
        final repo = await createRepository();
        await _seedFeedA(repo, 5);

        // When: limit 0 で取得する
        final call = repo.find(limit: 0);

        // Then: ArgumentError
        await expectLater(call, throwsArgumentError);
      });

      // T42
      test('should throw ArgumentError when offset is negative', () async {
        // Given: 5件保存済み
        final repo = await createRepository();
        await _seedFeedA(repo, 5);

        // When: offset -1 で取得する
        final call = repo.find(offset: -1);

        // Then: ArgumentError
        await expectLater(call, throwsArgumentError);
      });

      // P2
      for (var n = 0; n <= 7; n++) {
        for (var k = 1; k <= 4; k++) {
          test('should concatenate pages into full list when $n saved '
              'and page size is $k', () async {
            // Given: n 件保存済み
            final repo = await createRepository();
            await _seedFeedA(repo, n);
            final full = await repo.find();

            // When: offset を 0, k, 2k, … と進め、空になるまでページを連結する
            final concatenated = <StoredArticle>[];
            for (var offset = 0; ; offset += k) {
              final page = await repo.find(limit: k, offset: offset);
              if (page.isEmpty) break;
              concatenated.addAll(page);
            }

            // Then: limit なしの結果と一致する
            expect(concatenated, equals(full));
          });
        }
      }
    });

    group('setRead', () {
      // T43
      test(
        'should reflect read state when setRead is called with true',
        () async {
          // Given: 未読の記事
          final repo = await createRepository();
          final stored = await repo.addAll('feed-a', [rss(1)]);

          // When: 既読にする
          final r = await repo.setRead(stored[0].id, isRead: true);

          // Then: 戻り値にも再取得にも反映される
          final expected = StoredArticle(
            id: stored[0].id,
            feedId: 'feed-a',
            article: rss(1),
            isRead: true,
          );
          expect(r, equals(expected));
          expect(await repo.findById(stored[0].id), equals(expected));
        },
      );

      // T44
      test(
        'should return to unread when setRead is called with false',
        () async {
          // Given: 既読の記事
          final repo = await createRepository();
          final stored = await repo.addAll('feed-a', [rss(1)]);
          await repo.setRead(stored[0].id, isRead: true);

          // When: 未読に戻す
          final r = await repo.setRead(stored[0].id, isRead: false);
          final unread = await repo.find(unreadOnly: true);

          // Then: 未読になり、未読一覧に含まれる
          expect(r.isRead, isFalse);
          expect(unread.map((s) => s.id), contains(stored[0].id));
        },
      );

      // T45
      test('should not throw when setRead is called with same value', () async {
        // Given: 既読の記事
        final repo = await createRepository();
        final stored = await repo.addAll('feed-a', [rss(1)]);
        await repo.setRead(stored[0].id, isRead: true);

        // When: もう一度既読にする
        final r = await repo.setRead(stored[0].id, isRead: true);

        // Then: 既読のままで、例外は発生しない
        expect(r.isRead, isTrue);
      });

      // T46
      test(
        'should throw ArticleNotFoundException when id does not exist',
        () async {
          // Given: 空のリポジトリ
          final repo = await createRepository();

          // When: 存在しない記事を更新する
          final call = repo.setRead('missing', isRead: true);

          // Then: ArticleNotFoundException が投げられる
          await expectLater(
            call,
            throwsA(
              isA<ArticleNotFoundException>().having(
                (e) => e.id,
                'id',
                'missing',
              ),
            ),
          );
        },
      );
    });

    group('findById', () {
      // T17
      test('should return stored article when id is registered', () async {
        // Given: 保存済みの記事
        final repo = await createRepository();
        final stored = await repo.addAll('feed-a', [rss(1)]);

        // When: ID で取得する
        final found = await repo.findById(stored[0].id);

        // Then: 保存した記事と等しい
        expect(found, equals(stored[0]));
      });

      // T20
      test('should return null when id does not exist', () async {
        // Given: 1件保存済みのリポジトリ
        final repo = await createRepository();
        await repo.addAll('feed-a', [rss(1)]);

        // When: 存在しない ID で取得する
        final found = await repo.findById('missing');

        // Then: null
        expect(found, isNull);
      });
    });
  });
}
