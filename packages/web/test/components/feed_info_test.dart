import 'package:jaspr_test/jaspr_test.dart';
import 'package:shared/shared.dart';
import 'package:web_app/src/components/feed_info.dart';

void main() {
  final displaySummary = FeedSummary(
    title: '水無瀬のプログラミング日記feed',
    url: 'https://tminasen.dev/rss/feed.xml',
    lastFetchedAt: DateTime(2026, 11, 15, 10, 30),
    articleCount: 10,
  );

  group('FeedInfo', () {
    testComponents('should render feed title when summary has title', (
      tester,
    ) async {
      // Given: タイトルありの FeedSummary

      // When: FeedInfo を描画する
      tester.pumpComponent(FeedInfo(summary: displaySummary));

      // Then: タイトルが描画される
      expect(find.text('水無瀬のプログラミング日記feed'), findsOneComponent);
    });

    testComponents('should render feed url when summary is given', (
      tester,
    ) async {
      // Given: displaySummary

      // When: FeedInfo を描画する
      tester.pumpComponent(FeedInfo(summary: displaySummary));

      // Then: URL が描画される
      expect(find.text('https://tminasen.dev/rss/feed.xml'), findsOneComponent);
    });

    testComponents(
      'should render last fetched time and article count when summary is given',
      (tester) async {
        // Given: displaySummary

        // When: FeedInfo を描画する
        tester.pumpComponent(FeedInfo(summary: displaySummary));

        // Then: 最終取得日時と件数が描画される
        expect(find.text('最終取得 2026/11/15 10:30 ・ 全10件'), findsOneComponent);
      },
    );

    testComponents('should render placeholder title when title is null', (
      tester,
    ) async {
      // Given: title が null の FeedSummary
      final summary = FeedSummary(
        title: null,
        url: displaySummary.url,
        lastFetchedAt: displaySummary.lastFetchedAt,
        articleCount: displaySummary.articleCount,
      );

      // When: FeedInfo を描画する
      tester.pumpComponent(FeedInfo(summary: summary));

      // Then: 「タイトル未取得」が描画される
      expect(find.text('タイトル未取得'), findsOneComponent);
    });

    testComponents(
      'should render a section element as the root when summary is given',
      (tester) async {
        // Given: displaySummary

        // When: FeedInfo を描画する
        tester.pumpComponent(FeedInfo(summary: displaySummary));

        // Then: ルート要素として section 要素が1件描画される
        expect(find.tag('section'), findsOneComponent);
      },
    );
  });
}
