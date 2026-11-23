import 'dart:math';

import 'package:server/src/repository/article_repository.dart';
import 'package:server/src/repository/in_memory_article_repository.dart';
import 'package:server/src/repository/repository_exception.dart';
import 'package:server/src/repository/sqlite_article_repository.dart';
import 'package:server/src/repository/stored_article.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'article_repository_contract.dart';
import 'fixtures.dart';
import 'sqlite_fixtures.dart';

void main() {
  articleRepositoryContract(
    () async => SqliteArticleRepository(openMigratedInMemory()),
  );

  group('SqliteArticleRepository (reopen)', () {
    test(
      'should keep articles and read state when database is reopened',
      () async {
        // Given: 2件保存して1件を既読にし、閉じたファイル DB
        final path = tempDbPath();
        final db1 = reopen(path);
        final repo1 = SqliteArticleRepository(db1);
        final stored = await repo1.addAll('feed-a', [rss(1), rss(2)]);
        await repo1.setRead(stored[0].id, isRead: true);
        db1.close();

        // When: 開き直して全件取得する
        final found = await SqliteArticleRepository(reopen(path)).find();

        // Then: 基準日時の新しい順で、既読状態も戻る
        expect(found, [
          StoredArticle(
            id: stored[1].id,
            feedId: 'feed-a',
            article: rss(2),
            isRead: false,
          ),
          StoredArticle(
            id: stored[0].id,
            feedId: 'feed-a',
            article: rss(1),
            isRead: true,
          ),
        ]);
      },
    );

    test('should still deduplicate when database is reopened', () async {
      // Given: 2件保存して閉じたファイル DB
      final path = tempDbPath();
      final db1 = reopen(path);
      await SqliteArticleRepository(db1).addAll('feed-a', [rss(1), rss(2)]);
      db1.close();

      // When: 開き直して既存の記事をもう一度追加する
      final repo2 = SqliteArticleRepository(reopen(path));
      final added = await repo2.addAll('feed-a', [rss(1)]);

      // Then: 何も追加されず、2件のまま
      expect(added, isEmpty);
      expect(await repo2.find(feedId: 'feed-a'), hasLength(2));
    });

    test('should not reuse article id when added after reopen', () async {
      // Given: 2件保存して閉じたファイル DB
      final path = tempDbPath();
      final db1 = reopen(path);
      final first = await SqliteArticleRepository(
        db1,
      ).addAll('feed-a', [rss(1), rss(2)]);
      db1.close();

      // When: 開き直して別の記事を追加する
      final added = await SqliteArticleRepository(
        reopen(path),
      ).addAll('feed-a', [rss(3)]);

      // Then: 1件で、ID は最初の2件のどちらとも違う
      expect(added, hasLength(1));
      expect([for (final a in first) a.id], isNot(contains(added.single.id)));
    });

    test('should restore atom and enclosure content when reopened', () async {
      // Given: Atom 記事と enclosure 付き RSS 記事を保存して閉じたファイル DB
      final path = tempDbPath();
      final db1 = reopen(path);
      final stored = await SqliteArticleRepository(
        db1,
      ).addAll('feed-b', [atomArticle, rssWithEnclosure]);
      db1.close();

      // When: 開き直して ID で取得する
      final repo2 = SqliteArticleRepository(reopen(path));
      final found = [for (final s in stored) await repo2.findById(s.id)];

      // Then: 内容がそのまま戻る
      expect(found, [
        StoredArticle(
          id: stored[0].id,
          feedId: 'feed-b',
          article: atomArticle,
          isRead: false,
        ),
        StoredArticle(
          id: stored[1].id,
          feedId: 'feed-b',
          article: rssWithEnclosure,
          isRead: false,
        ),
      ]);
    });
  });

  group('SqliteArticleRepository (non-canonical id)', () {
    for (final id in ['01', '+1', '0x1', ' 1']) {
      test(
        'should treat id as not found when id is non-canonical "$id"',
        () async {
          // Given: ID '1' を採番済みの記事
          final repo = SqliteArticleRepository(openMigratedInMemory());
          final stored = await repo.addAll('feed-a', [rss(1)]);
          expect(stored.single.id, '1');

          // When / Then: 非正規表記の ID は見つからない扱いで、更新もされない
          expect(await repo.findById(id), isNull);
          await expectLater(
            repo.setRead(id, isRead: true),
            throwsA(isA<ArticleNotFoundException>()),
          );
          expect((await repo.findById('1'))!.isRead, isFalse);
        },
      );
    }
  });

  group('SqliteArticleRepository vs InMemoryArticleRepository', () {
    // 同じ操作列を当てると、find の結果が両実装で一致する
    for (var seed = 0; seed < 20; seed++) {
      test(
        'should return same results as in-memory when seed is $seed',
        () async {
          // Given: シード固定の操作列と、2つの実装
          final random = Random(seed);
          final operations = _randomOperations(random);
          final inMemory = InMemoryArticleRepository();
          final sqlite = SqliteArticleRepository(openMigratedInMemory());

          // When: 同じ操作列を両方に当てる
          for (final repo in [inMemory, sqlite]) {
            await _apply(repo, operations);
          }

          // Then: 全件と絞り込み＋ページングの結果が、ID を除いて一致する
          expect(_view(await sqlite.find()), _view(await inMemory.find()));
          expect(
            _view(
              await sqlite.find(
                feedId: 'feed-a',
                unreadOnly: true,
                limit: 2,
                offset: 1,
              ),
            ),
            _view(
              await inMemory.find(
                feedId: 'feed-a',
                unreadOnly: true,
                limit: 2,
                offset: 1,
              ),
            ),
          );
        },
      );
    }
  });
}

/// addAll の呼び出しと、その戻り値から添字で選んだ記事への setRead。
typedef _Operation = ({
  String feedId,
  List<Article> articles,
  List<({int index, bool isRead})> reads,
});

List<Article> _candidates() => [
  for (var n = 1; n <= 10; n++) rss(n),
  for (var n = 1; n <= 3; n++)
    RssArticle(link: 'https://tminasen.dev/posts/$n'),
  RssArticle(guid: '', link: ''),
  atomArticle,
  for (var n = 1; n <= 2; n++) RssArticle(guid: 'nodate-$n'),
];

List<_Operation> _randomOperations(Random random) {
  final candidates = _candidates();
  final operationCount = 1 + random.nextInt(5);
  return [
    for (var i = 0; i < operationCount; i++)
      (
        feedId: random.nextBool() ? 'feed-a' : 'feed-b',
        articles: [
          for (final _ in List.filled(random.nextInt(6), null))
            candidates[random.nextInt(candidates.length)],
        ],
        reads: [
          for (final _ in List.filled(random.nextInt(4), null))
            (index: random.nextInt(6), isRead: random.nextBool()),
        ],
      ),
  ];
}

Future<void> _apply(ArticleRepository repo, List<_Operation> operations) async {
  for (final op in operations) {
    final added = await repo.addAll(op.feedId, op.articles);
    if (added.isEmpty) continue;
    for (final read in op.reads) {
      await repo.setRead(
        added[read.index % added.length].id,
        isRead: read.isRead,
      );
    }
  }
}

List<(String, Article, bool)> _view(List<StoredArticle> articles) => [
  for (final a in articles) (a.feedId, a.article, a.isRead),
];
