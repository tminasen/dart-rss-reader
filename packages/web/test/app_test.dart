import 'package:jaspr_test/jaspr_test.dart';
import 'package:shared/shared.dart';
import 'package:web_app/app.dart';

final feedSummaryA = FeedSummary(
  title: 'tminasen.dev',
  url: 'https://tminasen.dev/rss/feed.xml',
  lastFetchedAt: DateTime.utc(2026, 4, 14, 9),
  articleCount: 1,
);

final rssArticleA = RssArticle(
  title: 'Angularを使ってボードゲームの得点計算ツールを作った話',
  link: 'https://tminasen.dev/blog/1',
  pubDate: DateTime(2026, 4, 14),
  enclosure: const RssEnclosure(
    url: 'https://tminasen.dev/images/1.png',
    length: 0,
    type: 'image/png',
  ),
);

final unreadItemA = ArticleItem(
  id: 'a-1',
  feedId: 'f-1',
  isRead: false,
  article: rssArticleA,
);

void main() {
  group('App', () {
    // T53
    testComponents(
      'should render Header, FeedInfoSection, and ArticleListSection with loaded data',
      (tester) async {
        // Given: フィード1件と記事1件を返す各フェイク関数
        Future<List<FeedSummary>> loadFeeds() async => [feedSummaryA];
        Future<List<ArticleItem>> loadArticles() async => [unreadItemA];
        Future<ArticleItem> dummyUpdate(
          String id, {
          required bool isRead,
        }) async {
          return unreadItemA;
        }

        // When: App を描画し、非同期読み込みの完了を待つ
        tester.pumpComponent(
          App(
            loadFeeds: loadFeeds,
            loadArticles: loadArticles,
            updateArticleRead: dummyUpdate,
          ),
        );
        await tester.pump();

        // Then: アプリ名、フィードタイトル、フィルタ件数、記事タイトルがすべて描画される
        expect(find.text('Dart RSS Reader'), findsOneComponent);
        expect(find.text('tminasen.dev'), findsOneComponent);
        expect(find.text('すべて 1'), findsOneComponent);
        expect(find.text('Angularを使ってボードゲームの得点計算ツールを作った話'), findsOneComponent);
      },
    );
  });
}
