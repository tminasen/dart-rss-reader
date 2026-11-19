/// 指定された ID の購読が存在しない。
final class SubscriptionNotFoundException implements Exception {
  const SubscriptionNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'SubscriptionNotFoundException: $id';
}

/// 指定された ID の記事が存在しない。
final class ArticleNotFoundException implements Exception {
  const ArticleNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'ArticleNotFoundException: $id';
}
