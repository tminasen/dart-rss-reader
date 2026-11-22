// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedSummary _$FeedSummaryFromJson(Map<String, dynamic> json) => FeedSummary(
  title: json['title'] as String?,
  url: json['url'] as String,
  lastFetchedAt: json['lastFetchedAt'] == null
      ? null
      : DateTime.parse(json['lastFetchedAt'] as String),
  articleCount: (json['articleCount'] as num).toInt(),
);

Map<String, dynamic> _$FeedSummaryToJson(FeedSummary instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'lastFetchedAt': instance.lastFetchedAt?.toIso8601String(),
      'articleCount': instance.articleCount,
    };
