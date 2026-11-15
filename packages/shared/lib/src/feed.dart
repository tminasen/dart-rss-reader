import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'feed.g.dart';

sealed class Feed extends Equatable {
  const Feed();

  factory Feed.fromJson(Map<String, dynamic> json) {
    return switch (json['format']) {
      'rss' => RssFeed.fromJson(json),
      'atom' => AtomFeed.fromJson(json),
      _ => throw FormatException('Unknown feed format', json['format']),
    };
  }

  String get title;
  String? get link;

  Map<String, dynamic> toJson();
}

@JsonSerializable()
final class RssFeed extends Feed {
  const RssFeed({
    required this.title,
    required this.link,
    required this.description,
    this.lastBuildDate,
    this.language,
    this.imageUrl,
  });

  factory RssFeed.fromJson(Map<String, dynamic> json) =>
      _$RssFeedFromJson(json);

  @override
  final String title;
  @override
  final String link;
  final String description;
  final DateTime? lastBuildDate;
  final String? language;
  final String? imageUrl;

  @override
  List<Object?> get props => [
    title,
    link,
    description,
    lastBuildDate,
    language,
    imageUrl,
  ];

  @override
  Map<String, dynamic> toJson() => {'format': 'rss', ..._$RssFeedToJson(this)};
}

@JsonSerializable()
final class AtomFeed extends Feed {
  const AtomFeed({
    required this.id,
    required this.title,
    required this.updated,
    this.link,
    this.subtitle,
  });

  factory AtomFeed.fromJson(Map<String, dynamic> json) =>
      _$AtomFeedFromJson(json);

  final String id;
  @override
  final String title;
  final DateTime updated;
  @override
  final String? link;
  final String? subtitle;

  @override
  List<Object?> get props => [id, title, updated, link, subtitle];

  @override
  Map<String, dynamic> toJson() => {
    'format': 'atom',
    ..._$AtomFeedToJson(this),
  };
}
