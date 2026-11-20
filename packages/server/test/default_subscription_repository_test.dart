import 'package:server/src/default_subscription_repository.dart';
import 'package:test/test.dart';

import 'repository/fixtures.dart';

void main() {
  group('createDefaultSubscriptionRepository', () {
    test(
      'should register only the fixed feed URL as unfetched when created',
      () async {
        // Given: なし

        // When: 既定リポジトリを生成して全件取得する
        final repo = await createDefaultSubscriptionRepository();
        final subscriptions = await repo.findAll();

        // Then: 固定URLが1件だけ、未取得状態で登録されている
        expect(subscriptions, hasLength(1));
        expect(subscriptions[0].feedUrl, equals(feedUrlA));
        expect(subscriptions[0].feed, isNull);
        expect(subscriptions[0].lastFetchedAt, isNull);
      },
    );
  });
}
