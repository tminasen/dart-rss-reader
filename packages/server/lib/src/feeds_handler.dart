import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';

import 'repository/article_repository.dart';
import 'repository/subscription_repository.dart';

Handler feedsHandler(
  SubscriptionRepository subscriptions,
  ArticleRepository articles,
) {
  return (Request request) async {
    final found = await subscriptions.findAll();
    final summaries = [
      for (final subscription in found)
        FeedSummary(
          title: subscription.feed?.title,
          url: subscription.feedUrl,
          lastFetchedAt: subscription.lastFetchedAt?.toUtc(),
          articleCount: (await articles.find(feedId: subscription.id)).length,
        ),
    ];
    return Response.ok(
      jsonEncode(summaries.map((s) => s.toJson()).toList()),
      headers: {'content-type': 'application/json'},
    );
  };
}
