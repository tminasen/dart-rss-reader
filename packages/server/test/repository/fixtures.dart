import 'package:shared/shared.dart';

const feedUrlA = 'https://tminasen.dev/rss/feed.xml';
const feedUrlB = 'https://example.com/atom.xml';

final rssFeed = RssFeed(
  title: 'tminasen.dev',
  link: 'https://tminasen.dev/',
  description: 'tminasen のブログ',
);

final atomFeed = AtomFeed(
  id: 'tag:example.com,2026:feed',
  title: 'Example Atom',
  updated: DateTime.utc(2026, 11, 14),
);

final fetchedAt1 = DateTime.utc(2026, 11, 19, 9);
final fetchedAt2 = DateTime.utc(2026, 11, 19, 10);

RssArticle rss(int n) => RssArticle(
  title: '記事$n',
  link: 'https://tminasen.dev/posts/$n',
  guid: 'post-$n',
  pubDate: DateTime.utc(2026, 11, n),
);

final atomArticle = AtomArticle(
  id: 'tag:example.com,2026:entry-1',
  title: 'Atom 記事',
  updated: DateTime.utc(2026, 11, 10),
  published: DateTime.utc(2026, 11, 9),
);
