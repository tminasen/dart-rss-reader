import 'dart:async';

import 'feed_client.dart';
import 'repository/article_repository.dart';
import 'repository/stored_article.dart';
import 'repository/subscription.dart';
import 'repository/subscription_repository.dart';

/// 登録済みのフィードを取得して記事を保存し、新着を [newArticles] に流す。
final class FeedCrawler {
  FeedCrawler({
    required SubscriptionRepository subscriptions,
    required ArticleRepository articles,
    required FeedClient client,
    required List<String> feedUrls,
    DateTime Function() now = DateTime.now,
    void Function(String feedUrl, Object error, StackTrace stackTrace)? onError,
  }) : _subscriptions = subscriptions,
       _articles = articles,
       _client = client,
       _feedUrls = feedUrls,
       _now = now,
       _onError = onError;

  final SubscriptionRepository _subscriptions;
  final ArticleRepository _articles;
  final FeedClient _client;
  final List<String> _feedUrls;
  final DateTime Function() _now;
  final void Function(String feedUrl, Object error, StackTrace stackTrace)?
  _onError;
  final _newArticles = StreamController<StoredArticle>.broadcast();

  /// 保存に成功した記事を保存順に流す。購読者がいなければ捨てられる。
  Stream<StoredArticle> get newArticles => _newArticles.stream;

  /// 設定のURLのうち購読済みのフィードを1回ずつ取得して保存する。
  /// 1フィードの失敗は `onError` に渡し、残りのフィードの巡回を続ける。
  Future<void> crawl() async {
    final subscriptions = await _subscriptions.findAll();
    for (final subscription in subscriptions) {
      if (!_feedUrls.contains(subscription.feedUrl)) continue;
      try {
        await _crawlOne(subscription);
      } on Object catch (error, stackTrace) {
        _onError?.call(subscription.feedUrl, error, stackTrace);
      }
    }
  }

  Future<void> _crawlOne(Subscription subscription) async {
    final result = await _client.fetch(Uri.parse(subscription.feedUrl));
    if (result is! FeedUpdated) return;
    final saved = await _articles.addAll(subscription.id, result.articles);
    // 記録に失敗しても、保存済みの記事は次回以降の巡回で新着に戻らないため先に流す。
    saved.forEach(_newArticles.add);
    await _subscriptions.updateFetched(
      subscription.id,
      feed: result.feed,
      fetchedAt: _now(),
    );
  }

  Future<void> close() => _newArticles.close();
}
