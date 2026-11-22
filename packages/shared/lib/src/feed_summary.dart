import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'feed_summary.g.dart';

/// `GET /feeds` の1要素。購読中のフィードの概要。
@JsonSerializable()
final class FeedSummary extends Equatable {
  const FeedSummary({
    required this.title,
    required this.url,
    required this.lastFetchedAt,
    required this.articleCount,
  });

  factory FeedSummary.fromJson(Map<String, dynamic> json) =>
      _$FeedSummaryFromJson(json);

  /// フィードのタイトル。未取得なら null。
  final String? title;
  final String url;

  /// 最終取得日時。未取得なら null。
  final DateTime? lastFetchedAt;

  /// 既読・未読を問わない、そのフィードの全記事件数。
  final int articleCount;

  @override
  List<Object?> get props => [title, url, lastFetchedAt, articleCount];

  Map<String, dynamic> toJson() => _$FeedSummaryToJson(this);
}
