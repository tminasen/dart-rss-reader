import 'package:equatable/equatable.dart';

import 'article.dart';

/// API でやり取りする既読状態付きの記事項目。
final class ArticleItem extends Equatable {
  const ArticleItem({
    required this.id,
    required this.feedId,
    required this.isRead,
    required this.article,
  });

  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    return ArticleItem(
      id: json['id'] as String,
      feedId: json['feedId'] as String,
      isRead: json['isRead'] as bool,
      article: Article.fromJson(json['article'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String feedId;
  final bool isRead;
  final Article article;

  @override
  List<Object?> get props => [id, feedId, isRead, article];

  Map<String, dynamic> toJson() => {
    'id': id,
    'feedId': feedId,
    'isRead': isRead,
    'article': article.toJson(),
  };
}
