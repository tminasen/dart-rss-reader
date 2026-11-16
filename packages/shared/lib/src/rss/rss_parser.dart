import 'package:xml/xml.dart';

import '../article.dart';
import '../feed.dart';
import 'rfc822_date.dart';
import 'rss_parse_exception.dart';

typedef RssParseResult = ({RssFeed feed, List<RssArticle> articles});

/// RSS 2.0 の XML 文字列を [RssFeed] と [RssArticle] のリストに変換する。
///
/// 解釈できない場合は [RssParseException] のサブタイプを投げる。
RssParseResult parseRss(String xml) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw MalformedXmlException(e.message);
  }

  final root = document.rootElement;
  if (root.name.prefix != null || root.name.local != 'rss') {
    throw const NotRssFeedException('Root element is not <rss>');
  }
  final channel = _child(root, 'channel');
  if (channel == null) {
    throw const NotRssFeedException('<channel> is missing');
  }

  final feed = RssFeed(
    title: _requiredText(channel, 'title'),
    link: _requiredText(channel, 'link'),
    description: _requiredText(channel, 'description'),
    lastBuildDate: _optionalDate(channel, 'lastBuildDate'),
    language: _optionalText(channel, 'language'),
    imageUrl: _optionalText(_child(channel, 'image'), 'url'),
  );
  final articles = [
    for (final item in channel.childElements)
      if (item.name.prefix == null && item.name.local == 'item')
        _parseItem(item),
  ];
  return (feed: feed, articles: articles);
}

/// 直下の子要素のうち、名前空間プレフィックスなしで名前が [name] の最初の要素。
XmlElement? _child(XmlElement parent, String name) {
  for (final child in parent.childElements) {
    if (child.name.prefix == null && child.name.local == name) return child;
  }
  return null;
}

String _requiredText(XmlElement parent, String name) {
  final element = _child(parent, name);
  if (element == null) throw MissingRequiredElementException(name);
  return element.innerText.trim();
}

String? _optionalText(XmlElement? parent, String name) {
  if (parent == null) return null;
  return _child(parent, name)?.innerText.trim();
}

DateTime? _optionalDate(XmlElement parent, String name) {
  final text = _optionalText(parent, name);
  return text == null ? null : parseRfc822Date(text);
}

RssArticle _parseItem(XmlElement item) {
  return RssArticle(
    title: _optionalText(item, 'title'),
    link: _optionalText(item, 'link'),
    guid: _optionalText(item, 'guid'),
    pubDate: _optionalDate(item, 'pubDate'),
    description: _optionalText(item, 'description'),
    enclosure: _parseEnclosure(_child(item, 'enclosure')),
  );
}

/// url / length / type がそろい length が整数のときだけ [RssEnclosure] を返す。
RssEnclosure? _parseEnclosure(XmlElement? element) {
  if (element == null) return null;
  final url = element.getAttribute('url');
  final type = element.getAttribute('type');
  final length = int.tryParse(element.getAttribute('length') ?? '');
  if (url == null || type == null || length == null) return null;
  return RssEnclosure(url: url, length: length, type: type);
}
