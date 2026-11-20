import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'repository/subscription.dart';
import 'repository/subscription_repository.dart';

Handler feedsHandler(SubscriptionRepository repository) {
  return (Request request) async {
    final subscriptions = await repository.findAll();
    return Response.ok(
      jsonEncode(subscriptions.map(_toJson).toList()),
      headers: {'content-type': 'application/json'},
    );
  };
}

Map<String, Object?> _toJson(Subscription subscription) => {
  'title': subscription.feed?.title,
  'url': subscription.feedUrl,
  'lastFetchedAt': subscription.lastFetchedAt?.toUtc().toIso8601String(),
};
