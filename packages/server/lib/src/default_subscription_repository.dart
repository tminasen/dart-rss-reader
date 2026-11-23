import 'repository/in_memory_subscription_repository.dart';
import 'repository/subscription_repository.dart';

/// 起動時に [feedUrl] を未取得状態で登録したリポジトリを返す。
/// [repository] を省略するとインメモリのリポジトリを使う。
/// 登録済みの URL は重複して登録されない。
Future<SubscriptionRepository> createDefaultSubscriptionRepository({
  SubscriptionRepository? repository,
  required String feedUrl,
}) async {
  final target = repository ?? InMemorySubscriptionRepository();
  await target.add(feedUrl);
  return target;
}
