import 'package:server/src/repository/repository_exception.dart';
import 'package:server/src/repository/sqlite_subscription_repository.dart';
import 'package:server/src/repository/subscription.dart';
import 'package:test/test.dart';

import 'fixtures.dart';
import 'sqlite_fixtures.dart';
import 'subscription_repository_contract.dart';

void main() {
  subscriptionRepositoryContract(
    () async => SqliteSubscriptionRepository(openMigratedInMemory()),
  );

  group('SqliteSubscriptionRepository (non-canonical id)', () {
    for (final id in ['01', '+1', '0x1', ' 1']) {
      test(
        'should treat id as not found when id is non-canonical "$id"',
        () async {
          // Given: ID '1' を採番済みの購読
          final repo = SqliteSubscriptionRepository(openMigratedInMemory());
          final s = await repo.add(feedUrlA);
          expect(s.id, '1');

          // When / Then: 非正規表記の ID は見つからない扱いで、更新もされない
          expect(await repo.findById(id), isNull);
          await expectLater(
            repo.updateFetched(id, feed: rssFeed, fetchedAt: fetchedAt1),
            throwsA(isA<SubscriptionNotFoundException>()),
          );
          expect((await repo.findById('1'))!.feed, isNull);
        },
      );
    }
  });

  group('SqliteSubscriptionRepository (reopen)', () {
    test(
      'should keep fetched rss subscription when database is reopened',
      () async {
        // Given: 取得済みの購読を書いて閉じたファイル DB
        final path = tempDbPath();
        final db1 = reopen(path);
        final repo1 = SqliteSubscriptionRepository(db1);
        final s = await repo1.add(feedUrlA);
        await repo1.updateFetched(s.id, feed: rssFeed, fetchedAt: fetchedAt1);
        db1.close();

        // When: 開き直して全件取得する
        final repo2 = SqliteSubscriptionRepository(reopen(path));
        final all = await repo2.findAll();

        // Then: 内容がそのまま戻る（isUtc まで一致）
        expect(all, [
          Subscription(
            id: s.id,
            feedUrl: feedUrlA,
            feed: rssFeed,
            lastFetchedAt: fetchedAt1,
          ),
        ]);
        expect(all.single.lastFetchedAt!.isUtc, isTrue);
      },
    );

    test(
      'should not reuse id and keep order when added after reopen',
      () async {
        // Given: 1件登録して閉じたファイル DB
        final path = tempDbPath();
        final db1 = reopen(path);
        final a = await SqliteSubscriptionRepository(db1).add(feedUrlA);
        db1.close();

        // When: 開き直して別の URL を追加する
        final repo2 = SqliteSubscriptionRepository(reopen(path));
        final b = await repo2.add(feedUrlB);
        final all = await repo2.findAll();

        // Then: ID が重ならず、登録順に並ぶ
        expect(b.id, isNot(a.id));
        expect([for (final s in all) s.feedUrl], [feedUrlA, feedUrlB]);
      },
    );

    test(
      'should keep atom feed and unfetched subscription when reopened',
      () async {
        // Given: Atom で取得済みの購読と未取得の購読を書いて閉じたファイル DB
        final path = tempDbPath();
        final db1 = reopen(path);
        final repo1 = SqliteSubscriptionRepository(db1);
        final a = await repo1.add(feedUrlA);
        final b = await repo1.add(feedUrlB);
        await repo1.updateFetched(b.id, feed: atomFeed, fetchedAt: fetchedAt2);
        db1.close();

        // When: 開き直して ID で取得する
        final repo2 = SqliteSubscriptionRepository(reopen(path));
        final foundA = await repo2.findById(a.id);
        final foundB = await repo2.findById(b.id);

        // Then: A は未取得のまま、B は Atom フィードと取得日時が戻る
        expect(foundA!.feed, isNull);
        expect(foundA.lastFetchedAt, isNull);
        expect(foundB!.feed, atomFeed);
        expect(foundB.lastFetchedAt, fetchedAt2);
      },
    );
  });
}
