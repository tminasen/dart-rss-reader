import 'package:server/src/repository/in_memory_subscription_repository.dart';

import 'subscription_repository_contract.dart';

void main() {
  subscriptionRepositoryContract(() async => InMemorySubscriptionRepository());
}
