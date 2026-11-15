// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RssFeed _$RssFeedFromJson(Map<String, dynamic> json) => RssFeed(
  title: json['title'] as String,
  link: json['link'] as String,
  description: json['description'] as String,
  lastBuildDate: json['lastBuildDate'] == null
      ? null
      : DateTime.parse(json['lastBuildDate'] as String),
  language: json['language'] as String?,
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$RssFeedToJson(RssFeed instance) => <String, dynamic>{
  'title': instance.title,
  'link': instance.link,
  'description': instance.description,
  'lastBuildDate': instance.lastBuildDate?.toIso8601String(),
  'language': instance.language,
  'imageUrl': instance.imageUrl,
};

AtomFeed _$AtomFeedFromJson(Map<String, dynamic> json) => AtomFeed(
  id: json['id'] as String,
  title: json['title'] as String,
  updated: DateTime.parse(json['updated'] as String),
  link: json['link'] as String?,
  subtitle: json['subtitle'] as String?,
);

Map<String, dynamic> _$AtomFeedToJson(AtomFeed instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'updated': instance.updated.toIso8601String(),
  'link': instance.link,
  'subtitle': instance.subtitle,
};
