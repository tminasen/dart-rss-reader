import 'package:server/src/repository/repository_exception.dart';
import 'package:server/src/repository/subscription.dart';
import 'package:server/src/repository/subscription_repository.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// [SubscriptionRepository] の実装が満たすべき契約。
/// 各テストで [createRepository] を呼び、新しいリポジトリを使う。
void subscriptionRepositoryContract(
  Future<SubscriptionRepository> Function() createRepository,
) {
  group('SubscriptionRepository', () {
    group('add', () {
      // T5
      test('should return unfetched subscription when url is added', () async {
        // Given: 空のリポジトリ
        final repo = await createRepository();

        // When: URL を登録する
        final s = await repo.add(feedUrlA);

        // Then: 未取得状態の購読が返る
        expect(s.feedUrl, feedUrlA);
        expect(s.feed, isNull);
        expect(s.lastFetchedAt, isNull);
        expect(s.id, isNotEmpty);
      });

      // T8
      test(
        'should return existing subscription when url is already added',
        () async {
          // Given: 登録済みの URL
          final repo = await createRepository();
          final s1 = await repo.add(feedUrlA);

          // When: 同じ URL を再登録する
          final s2 = await repo.add(feedUrlA);
          final all = await repo.findAll();

          // Then: 既存の購読が返り、件数は増えない
          expect(s2, equals(s1));
          expect(all, hasLength(1));
        },
      );
    });

    group('findById', () {
      // T6
      test('should return subscription when id is registered', () async {
        // Given: 登録済みの購読
        final repo = await createRepository();
        final s = await repo.add(feedUrlA);

        // When: ID で取得する
        final found = await repo.findById(s.id);

        // Then: 登録した購読と等しい
        expect(found, equals(s));
      });

      // T9
      test('should return null when id does not exist', () async {
        // Given: 1件登録済みのリポジトリ
        final repo = await createRepository();
        await repo.add(feedUrlA);

        // When: 存在しない ID で取得する
        final found = await repo.findById('missing');

        // Then: null
        expect(found, isNull);
      });
    });

    group('findByUrl', () {
      // T10
      test('should return subscription when url is registered', () async {
        // Given: 2件登録済みのリポジトリ
        final repo = await createRepository();
        await repo.add(feedUrlA);
        final sB = await repo.add(feedUrlB);

        // When: 登録済み URL で取得する
        final found = await repo.findByUrl(feedUrlB);

        // Then: その購読と等しい
        expect(found, equals(sB));
      });

      // T11
      test('should return null when url is not registered', () async {
        // Given: 1件登録済みのリポジトリ
        final repo = await createRepository();
        await repo.add(feedUrlA);

        // When: 未登録の URL で取得する
        final found = await repo.findByUrl(feedUrlB);

        // Then: null
        expect(found, isNull);
      });
    });

    group('findAll', () {
      // T7
      test(
        'should return all subscriptions in order when urls differ',
        () async {
          // Given: 異なる URL を2件登録する
          final repo = await createRepository();
          final sA = await repo.add(feedUrlA);
          final sB = await repo.add(feedUrlB);

          // When: 全件取得する
          final all = await repo.findAll();

          // Then: 別 ID で、登録順に返る
          expect(sA.id, isNot(sB.id));
          expect(all, equals([sA, sB]));
        },
      );

      // T12
      test('should return empty list when repository is empty', () async {
        // Given: 空のリポジトリ
        final repo = await createRepository();

        // When: 全件取得する
        final all = await repo.findAll();

        // Then: 空リスト
        expect(all, isEmpty);
      });
    });

    group('updateFetched', () {
      // T13
      test(
        'should reflect fetched result when updateFetched is called',
        () async {
          // Given: 登録済みの購読
          final repo = await createRepository();
          final s = await repo.add(feedUrlA);

          // When: 取得結果を記録する
          final u = await repo.updateFetched(
            s.id,
            feed: rssFeed,
            fetchedAt: fetchedAt1,
          );

          // Then: 戻り値にも再取得にも反映される
          expect(
            u,
            equals(
              Subscription(
                id: s.id,
                feedUrl: feedUrlA,
                feed: rssFeed,
                lastFetchedAt: fetchedAt1,
              ),
            ),
          );
          expect(await repo.findById(s.id), equals(u));
        },
      );

      // T14
      test('should overwrite with latest values when called twice', () async {
        // Given: 1回記録済みの購読
        final repo = await createRepository();
        final s = await repo.add(feedUrlA);
        await repo.updateFetched(s.id, feed: rssFeed, fetchedAt: fetchedAt1);

        // When: 2回目の記録をする
        await repo.updateFetched(s.id, feed: atomFeed, fetchedAt: fetchedAt2);
        final found = await repo.findById(s.id);

        // Then: 最新値に上書きされ、URL は変わらない
        expect(found?.feed, equals(atomFeed));
        expect(found?.lastFetchedAt, fetchedAt2);
        expect(found?.feedUrl, feedUrlA);
      });

      // T15
      test(
        'should throw SubscriptionNotFoundException when id does not exist',
        () async {
          // Given: 空のリポジトリ
          final repo = await createRepository();

          // When: 存在しない購読を更新する
          final call = repo.updateFetched(
            'missing',
            feed: rssFeed,
            fetchedAt: fetchedAt1,
          );

          // Then: SubscriptionNotFoundException が投げられる
          await expectLater(
            call,
            throwsA(
              isA<SubscriptionNotFoundException>().having(
                (e) => e.id,
                'id',
                'missing',
              ),
            ),
          );
        },
      );
    });
  });
}
