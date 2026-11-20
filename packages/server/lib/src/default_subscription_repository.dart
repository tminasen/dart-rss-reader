import 'repository/in_memory_subscription_repository.dart';
import 'repository/subscription_repository.dart';

const _defaultFeedUrl = 'https://tminasen.dev/rss/feed.xml';

/// 起動時に固定URLを未取得状態で登録したインメモリのリポジトリを返す。
Future<SubscriptionRepository> createDefaultSubscriptionRepository() async {
  final repository = InMemorySubscriptionRepository();
  await repository.add(_defaultFeedUrl);
  return repository;
}
