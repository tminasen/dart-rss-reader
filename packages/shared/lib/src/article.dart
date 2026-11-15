import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'article.g.dart';

sealed class Article extends Equatable {
  const Article();

  factory Article.fromJson(Map<String, dynamic> json) {
    return switch (json['format']) {
      'rss' => RssArticle.fromJson(json),
      'atom' => AtomArticle.fromJson(json),
      _ => throw FormatException('Unknown article format', json['format']),
    };
  }

  String? get title;
  String? get link;

  Map<String, dynamic> toJson();
}

@JsonSerializable(explicitToJson: true)
final class RssArticle extends Article {
  const RssArticle({
    this.title,
    this.link,
    this.guid,
    this.pubDate,
    this.description,
    this.enclosure,
  });

  factory RssArticle.fromJson(Map<String, dynamic> json) =>
      _$RssArticleFromJson(json);

  @override
  final String? title;
  @override
  final String? link;
  final String? guid;
  final DateTime? pubDate;
  final String? description;
  final RssEnclosure? enclosure;

  @override
  List<Object?> get props => [
    title,
    link,
    guid,
    pubDate,
    description,
    enclosure,
  ];

  @override
  Map<String, dynamic> toJson() => {
    'format': 'rss',
    ..._$RssArticleToJson(this),
  };
}

@JsonSerializable()
final class RssEnclosure extends Equatable {
  const RssEnclosure({
    required this.url,
    required this.length,
    required this.type,
  });

  factory RssEnclosure.fromJson(Map<String, dynamic> json) =>
      _$RssEnclosureFromJson(json);

  final String url;
  final int length;
  final String type;

  @override
  List<Object?> get props => [url, length, type];

  Map<String, dynamic> toJson() => _$RssEnclosureToJson(this);
}

@JsonSerializable()
final class AtomArticle extends Article {
  const AtomArticle({
    required this.id,
    required this.title,
    required this.updated,
    this.link,
    this.published,
    this.summary,
  });

  factory AtomArticle.fromJson(Map<String, dynamic> json) =>
      _$AtomArticleFromJson(json);

  final String id;
  @override
  final String title;
  final DateTime updated;
  @override
  final String? link;
  final DateTime? published;
  final String? summary;

  @override
  List<Object?> get props => [id, title, updated, link, published, summary];

  @override
  Map<String, dynamic> toJson() => {
    'format': 'atom',
    ..._$AtomArticleToJson(this),
  };
}
