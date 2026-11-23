import 'package:server/src/default_subscription_repository.dart';
import 'package:server/src/repository/in_memory_subscription_repository.dart';
import 'package:test/test.dart';

import 'repository/fixtures.dart';

void main() {
  group('createDefaultSubscriptionRepository', () {
    test(
      'should register only the fixed feed URL as unfetched when created',
      () async {
        // Given: なし

        // When: 既定リポジトリを生成して全件取得する
        final repo = await createDefaultSubscriptionRepository(
          feedUrl: feedUrlA,
        );
        final subscriptions = await repo.findAll();

        // Then: 固定URLが1件だけ、未取得状態で登録されている
        expect(subscriptions, hasLength(1));
        expect(subscriptions[0].feedUrl, equals(feedUrlA));
        expect(subscriptions[0].feed, isNull);
        expect(subscriptions[0].lastFetchedAt, isNull);
      },
    );

    test(
      'should register the given feed URL as unfetched when created',
      () async {
        // Given: 登録したいURL
        // When: そのURLで既定リポジトリを生成して全件取得する
        final repo = await createDefaultSubscriptionRepository(
          feedUrl: feedUrlB,
        );
        final subscriptions = await repo.findAll();

        // Then: 渡したURLが未取得状態で1件だけ登録されている
        expect(
          [for (final s in subscriptions) (s.feedUrl, s.feed, s.lastFetchedAt)],
          [(feedUrlB, null, null)],
        );
      },
    );

    test(
      'should not register the URL twice when it is already registered',
      () async {
        // Given: 同じURLを登録済みのリポジトリ
        final existing = InMemorySubscriptionRepository();
        await existing.add(feedUrlB);

        // When: 同じURLで既定リポジトリを生成して全件取得する
        final repo = await createDefaultSubscriptionRepository(
          repository: existing,
          feedUrl: feedUrlB,
        );
        final subscriptions = await repo.findAll();

        // Then: 1件のまま
        expect(subscriptions, hasLength(1));
        expect(subscriptions.single.feedUrl, equals(feedUrlB));
      },
    );
  });
}
