import 'dart:async';

import 'package:jaspr_test/jaspr_test.dart';
import 'package:shared/shared.dart';
import 'package:web_app/src/api/api_exception.dart';
import 'package:web_app/src/components/feed_info_section.dart';

void main() {
  final summaryA = FeedSummary(
    title: 'tminasen.dev',
    url: 'https://tminasen.dev/rss/feed.xml',
    lastFetchedAt: DateTime.utc(2026, 11, 19, 9),
    articleCount: 10,
  );
  const summaryB = FeedSummary(
    title: 'Example Atom',
    url: 'https://example.com/atom.xml',
    lastFetchedAt: null,
    articleCount: 0,
  );

  group('FeedInfoSection', () {
    testComponents('should render first feed when feeds are loaded', (
      tester,
    ) async {
      // Given: 2件のフィードを返す loadFeeds
      Future<List<FeedSummary>> loadFeeds() async => [summaryA, summaryB];

      // When: 描画し、Future の完了を待つ
      tester.pumpComponent(FeedInfoSection(loadFeeds: loadFeeds));
      await tester.pump();

      // Then: 先頭のフィードだけが描画される
      expect(find.text('tminasen.dev'), findsOneComponent);
      expect(find.text('Example Atom'), findsNothing);
    });

    testComponents('should render empty message when no feeds are loaded', (
      tester,
    ) async {
      // Given: 空のリストを返す loadFeeds
      Future<List<FeedSummary>> loadFeeds() async => [];

      // When: 描画し、Future の完了を待つ
      tester.pumpComponent(FeedInfoSection(loadFeeds: loadFeeds));
      await tester.pump();

      // Then: 「購読中のフィードがありません」が描画される
      expect(find.text('購読中のフィードがありません'), findsOneComponent);
    });

    testComponents('should render error message when loading fails', (
      tester,
    ) async {
      // Given: 例外を投げる loadFeeds
      Future<List<FeedSummary>> loadFeeds() async =>
          throw ApiConnectionException('connection refused');

      // When: 描画し、Future の完了を待つ
      tester.pumpComponent(FeedInfoSection(loadFeeds: loadFeeds));
      await tester.pump();

      // Then: 「フィード情報を取得できませんでした」が描画される
      expect(find.text('フィード情報を取得できませんでした'), findsOneComponent);
    });

    testComponents(
      'should render loading message when loading is not completed',
      (tester) async {
        // Given: 完了しない loadFeeds
        Future<List<FeedSummary>> loadFeeds() =>
            Completer<List<FeedSummary>>().future;

        // When: 描画する（完了は待たない）
        tester.pumpComponent(FeedInfoSection(loadFeeds: loadFeeds));

        // Then: 「読み込み中…」が描画される
        expect(find.text('読み込み中…'), findsOneComponent);
      },
    );
  });
}
