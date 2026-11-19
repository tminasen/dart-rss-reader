import 'package:shared/shared.dart';

/// 購読中のフィードと、最後に取得した結果。
final class Subscription {
  const Subscription({
    required this.id,
    required this.feedUrl,
    this.feed,
    this.lastFetchedAt,
  });

  final String id;
  final String feedUrl;
  final Feed? feed;
  final DateTime? lastFetchedAt;

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.id == id &&
      other.feedUrl == feedUrl &&
      other.feed == feed &&
      other.lastFetchedAt == lastFetchedAt;

  @override
  int get hashCode => Object.hash(id, feedUrl, feed, lastFetchedAt);
}
