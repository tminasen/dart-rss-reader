import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:web_app/src/article_view_helpers.dart';
import 'package:web_app/src/components/filter_tabs.dart';

Finder buttonWithText(String label) =>
    find.ancestor(of: find.text(label), matching: find.tag('button'));

void main() {
  group('FilterTabs', () {
    // T38
    testComponents(
      'should render all and unread buttons with aria-pressed states',
      (tester) async {
        // Given: all 選択中、全件 10、未読 3 の FilterTabs

        // When: FilterTabs を描画する
        tester.pumpComponent(
          FilterTabs(
            selected: ArticleFilter.all,
            allCount: 10,
            unreadCount: 3,
            onSelect: (_) {},
          ),
        );

        // Then: 「すべて 10」「未読 3」ボタンが各1件あり、aria-pressed が 'true' / 'false' になる
        final allButton = buttonWithText('すべて 10');
        final unreadButton = buttonWithText('未読 3');
        expect(allButton, findsOneComponent);
        expect(unreadButton, findsOneComponent);

        final allDom = allButton.evaluate().single.component as DomComponent;
        final unreadDom =
            unreadButton.evaluate().single.component as DomComponent;
        expect(allDom.attributes?['aria-pressed'], equals('true'));
        expect(unreadDom.attributes?['aria-pressed'], equals('false'));
      },
    );

    // T39
    testComponents(
      'should invoke onSelect with corresponding ArticleFilter when clicked',
      (tester) async {
        // Given: 選択履歴を記録する onSelect
        final selectedHistory = <ArticleFilter>[];
        tester.pumpComponent(
          FilterTabs(
            selected: ArticleFilter.all,
            allCount: 10,
            unreadCount: 3,
            onSelect: selectedHistory.add,
          ),
        );

        // When: 「未読 3」をクリックし、続けて「すべて 10」をクリックする
        await tester.click(buttonWithText('未読 3'));
        await tester.click(buttonWithText('すべて 10'));

        // Then: [ArticleFilter.unread, ArticleFilter.all] の順で呼ばれる
        expect(
          selectedHistory,
          equals([ArticleFilter.unread, ArticleFilter.all]),
        );
      },
    );

    // T40
    testComponents(
      'should render zero counts when allCount and unreadCount are 0',
      (tester) async {
        // Given: 件数がいずれも 0 の FilterTabs

        // When: FilterTabs を描画する
        tester.pumpComponent(
          FilterTabs(
            selected: ArticleFilter.all,
            allCount: 0,
            unreadCount: 0,
            onSelect: (_) {},
          ),
        );

        // Then: 「すべて 0」と「未読 0」が各1件描画される
        expect(buttonWithText('すべて 0'), findsOneComponent);
        expect(buttonWithText('未読 0'), findsOneComponent);
      },
    );
  });
}
