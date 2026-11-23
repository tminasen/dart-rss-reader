import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:shared/shared.dart';
import 'package:web_app/app.dart';
import 'package:web_app/src/realtime/connection_status.dart';

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

final newItem = ArticleItem(
  id: 'n-1',
  feedId: 'f-1',
  isRead: false,
  article: RssArticle(
    title: '新着記事のタイトル',
    link: 'https://tminasen.dev/blog/new',
    pubDate: DateTime(2026, 11, 15),
    enclosure: null,
  ),
);

Future<List<FeedSummary>> loadFeeds() async => [feedSummaryA];
Future<List<ArticleItem>> loadArticles() async => [unreadItemA];
Future<ArticleItem> dummyUpdate(String id, {required bool isRead}) async {
  return unreadItemA;
}

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

    testComponents('should reflect connection status changes in Header', (
      tester,
    ) async {
      // Given: 未接続の ValueNotifier を渡した App
      final status = ValueNotifier(ConnectionStatus.reconnecting);
      tester.pumpComponent(
        App(
          loadFeeds: loadFeeds,
          loadArticles: loadArticles,
          updateArticleRead: dummyUpdate,
          connectionStatus: status,
        ),
      );
      await tester.pump();
      expect(find.text('再接続中…'), findsOneComponent);

      // When: 接続済みに変える
      status.value = ConnectionStatus.connected;
      await tester.pump();

      // Then: Header が「リアルタイム接続中」になる
      expect(find.text('リアルタイム接続中'), findsOneComponent);
      expect(find.text('再接続中…'), findsNothing);
    });

    testComponents(
      'should deliver the new articles stream to the article list',
      (tester) async {
        // Given: 新着ストリームを渡した App
        final controller = StreamController<ArticleItem>.broadcast();
        addTearDown(controller.close);
        tester.pumpComponent(
          App(
            loadFeeds: loadFeeds,
            loadArticles: loadArticles,
            updateArticleRead: dummyUpdate,
            newArticles: controller.stream,
          ),
        );
        await tester.pump();

        // When: 新着を1件流す
        controller.add(newItem);
        await tester.pump();

        // Then: 記事タイトルとバナーが描画される
        expect(find.text('新着記事のタイトル'), findsOneComponent);
        expect(find.text('新着記事を1件受信しました'), findsOneComponent);
      },
    );
  });
}
