import 'package:shared/shared.dart';

/// フィードに紐づけて保存された記事と、その既読状態。
final class StoredArticle {
  const StoredArticle({
    required this.id,
    required this.feedId,
    required this.article,
    required this.isRead,
  });

  final String id;
  final String feedId;
  final Article article;
  final bool isRead;

  Map<String, Object?> toJson() => {
    'id': id,
    'feedId': feedId,
    'isRead': isRead,
    'article': article.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is StoredArticle &&
      other.id == id &&
      other.feedId == feedId &&
      other.article == article &&
      other.isRead == isRead;

  @override
  int get hashCode => Object.hash(id, feedId, article, isRead);
}
