/// RSS のパースに失敗したことを表す例外。
sealed class RssParseException implements Exception {
  const RssParseException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// XML として整形式でない。
final class MalformedXmlException extends RssParseException {
  const MalformedXmlException(super.message);
}

/// RSS ではない（ルートが `<rss>` でない、または channel がない）。
final class NotRssFeedException extends RssParseException {
  const NotRssFeedException(super.message);
}

/// channel の必須要素（title / link / description）が欠けている。
final class MissingRequiredElementException extends RssParseException {
  const MissingRequiredElementException(this.elementName)
    : super('Required element <$elementName> is missing');

  final String elementName;
}
