// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RssArticle _$RssArticleFromJson(Map<String, dynamic> json) => RssArticle(
  title: json['title'] as String?,
  link: json['link'] as String?,
  guid: json['guid'] as String?,
  pubDate: json['pubDate'] == null
      ? null
      : DateTime.parse(json['pubDate'] as String),
  description: json['description'] as String?,
  enclosure: json['enclosure'] == null
      ? null
      : RssEnclosure.fromJson(json['enclosure'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RssArticleToJson(RssArticle instance) =>
    <String, dynamic>{
      'title': instance.title,
      'link': instance.link,
      'guid': instance.guid,
      'pubDate': instance.pubDate?.toIso8601String(),
      'description': instance.description,
      'enclosure': instance.enclosure?.toJson(),
    };

RssEnclosure _$RssEnclosureFromJson(Map<String, dynamic> json) => RssEnclosure(
  url: json['url'] as String,
  length: (json['length'] as num).toInt(),
  type: json['type'] as String,
);

Map<String, dynamic> _$RssEnclosureToJson(RssEnclosure instance) =>
    <String, dynamic>{
      'url': instance.url,
      'length': instance.length,
      'type': instance.type,
    };

AtomArticle _$AtomArticleFromJson(Map<String, dynamic> json) => AtomArticle(
  id: json['id'] as String,
  title: json['title'] as String,
  updated: DateTime.parse(json['updated'] as String),
  link: json['link'] as String?,
  published: json['published'] == null
      ? null
      : DateTime.parse(json['published'] as String),
  summary: json['summary'] as String?,
);

Map<String, dynamic> _$AtomArticleToJson(AtomArticle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'updated': instance.updated.toIso8601String(),
      'link': instance.link,
      'published': instance.published?.toIso8601String(),
      'summary': instance.summary,
    };
