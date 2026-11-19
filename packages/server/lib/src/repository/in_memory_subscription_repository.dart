import 'package:shared/shared.dart';

import 'repository_exception.dart';
import 'subscription.dart';
import 'subscription_repository.dart';

final class InMemorySubscriptionRepository implements SubscriptionRepository {
  final List<Subscription> _subscriptions = [];
  int _nextId = 1;

  @override
  Future<Subscription> add(String feedUrl) async {
    final existing = await findByUrl(feedUrl);
    if (existing != null) return existing;

    final subscription = Subscription(id: '${_nextId++}', feedUrl: feedUrl);
    _subscriptions.add(subscription);
    return subscription;
  }

  @override
  Future<Subscription?> findById(String id) async {
    for (final s in _subscriptions) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<Subscription?> findByUrl(String feedUrl) async {
    for (final s in _subscriptions) {
      if (s.feedUrl == feedUrl) return s;
    }
    return null;
  }

  @override
  Future<List<Subscription>> findAll() async => List.of(_subscriptions);

  @override
  Future<Subscription> updateFetched(
    String id, {
    required Feed feed,
    required DateTime fetchedAt,
  }) async {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index < 0) throw SubscriptionNotFoundException(id);

    final updated = Subscription(
      id: id,
      feedUrl: _subscriptions[index].feedUrl,
      feed: feed,
      lastFetchedAt: fetchedAt,
    );
    _subscriptions[index] = updated;
    return updated;
  }
}
