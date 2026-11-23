import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:shared/shared.dart';
import 'package:web_app/src/components/article_card.dart';

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

final rssArticleB = RssArticle(
  title: 'styled-componentsからTailwindCSSに移行する際に困ったこと',
  link: 'https://tminasen.dev/blog/2',
  pubDate: DateTime(2025, 4, 14),
  enclosure: null,
);

final unreadItemA = ArticleItem(
  id: 'a-1',
  feedId: 'f-1',
  isRead: false,
  article: rssArticleA,
);

final readItemB = ArticleItem(
  id: 'a-2',
  feedId: 'f-1',
  isRead: true,
  article: rssArticleB,
);

void main() {
  group('ArticleCard', () {
    // T31
    testComponents(
      'should render thumbnail img, title, unread badge, date, and mark-read button for unread article',
      (tester) async {
        // Given: 画像 enclosure ありの未読記事 unreadItemA

        // When: ArticleCard を描画する
        tester.pumpComponent(
          ArticleCard(item: unreadItemA, onToggleRead: () {}),
        );

        // Then: img の src、タイトル、未読バッジ、日付、「既読にする」ボタンが描画される
        expect(
          find.byComponentPredicate(
            (c) =>
                c is DomComponent &&
                c.tag == 'img' &&
                c.attributes?['src'] == 'https://tminasen.dev/images/1.png',
          ),
          findsOneComponent,
        );
        expect(find.text('Angularを使ってボードゲームの得点計算ツールを作った話'), findsOneComponent);
        expect(find.text('未読'), findsOneComponent);
        expect(find.text('2026/04/14'), findsOneComponent);
        expect(find.text('既読にする'), findsOneComponent);
      },
    );

    // T32
    testComponents(
      'should render read label, date, and mark-unread button without img for read article without enclosure',
      (tester) async {
        // Given: enclosure なしの既読記事 readItemB

        // When: ArticleCard を描画する
        tester.pumpComponent(ArticleCard(item: readItemB, onToggleRead: () {}));

        // Then: img が 0 件で、既読ラベル・日付・「未読に戻す」が描画され、未読バッジと「既読にする」はない
        expect(find.tag('img'), findsNothing);
        expect(find.text('既読'), findsOneComponent);
        expect(find.text('2025/04/14'), findsOneComponent);
        expect(find.text('未読に戻す'), findsOneComponent);
        expect(find.text('未読'), findsNothing);
        expect(find.text('既読にする'), findsNothing);
      },
    );

    // T33
    testComponents(
      'should render title inside external anchor link when article link is valid',
      (tester) async {
        // Given: 有効な https リンクを持つ unreadItemA

        // When: ArticleCard を描画する
        tester.pumpComponent(
          ArticleCard(item: unreadItemA, onToggleRead: () {}),
        );

        // Then: target=_blank・rel=noopener noreferrer の a 要素が1件描画される
        expect(find.tag('a'), findsOneComponent);
        expect(
          find.byComponentPredicate(
            (c) =>
                c is DomComponent &&
                c.tag == 'a' &&
                c.attributes?['href'] == 'https://tminasen.dev/blog/1' &&
                c.attributes?['target'] == '_blank' &&
                c.attributes?['rel'] == 'noopener noreferrer',
          ),
          findsOneComponent,
        );
      },
    );

    // T34
    testComponents(
      'should render plain text title without anchor when link is null or javascript:',
      (tester) async {
        // Given: link が null の記事と javascript: の記事
        const nullLinkItem = ArticleItem(
          id: 'a-null',
          feedId: 'f-1',
          isRead: false,
          article: RssArticle(title: 'リンクなし', link: null),
        );
        const jsLinkItem = ArticleItem(
          id: 'a-js',
          feedId: 'f-1',
          isRead: false,
          article: RssArticle(title: 'リンクなし', link: 'javascript:alert(1)'),
        );

        // When: link が null の ArticleCard を描画する
        tester.pumpComponent(
          ArticleCard(item: nullLinkItem, onToggleRead: () {}),
        );

        // Then: a 要素は 0 件で、テキスト「リンクなし」が描画される
        expect(find.tag('a'), findsNothing);
        expect(find.text('リンクなし'), findsOneComponent);

        // When: link が javascript: の ArticleCard を描画する
        tester.pumpComponent(
          ArticleCard(item: jsLinkItem, onToggleRead: () {}),
        );

        // Then: a 要素は 0 件で、テキスト「リンクなし」が描画される
        expect(find.tag('a'), findsNothing);
        expect(find.text('リンクなし'), findsOneComponent);
      },
    );

    // T35
    testComponents(
      'should render 無題の記事 and omit date when title and pubDate are null',
      (tester) async {
        // Given: title と pubDate がともに null の記事
        const untitledItem = ArticleItem(
          id: 'a-4',
          feedId: 'f-1',
          isRead: false,
          article: RssArticle(title: null, pubDate: null),
        );

        // When: ArticleCard を描画する
        tester.pumpComponent(
          ArticleCard(item: untitledItem, onToggleRead: () {}),
        );

        // Then: 「無題の記事」と「未読」が描画され、'/' を含む日付テキストは描画されない
        expect(find.text('無題の記事'), findsOneComponent);
        expect(find.text('未読'), findsOneComponent);
        expect(find.textContaining('/'), findsNothing);
      },
    );

    // T36
    testComponents(
      'should invoke onToggleRead once when toggle button is clicked',
      (tester) async {
        // Given: unreadItemA と呼び出し回数カウンタ付き onToggleRead
        var count = 0;
        tester.pumpComponent(
          ArticleCard(item: unreadItemA, onToggleRead: () => count++),
        );

        // When: ボタンをクリックする
        await tester.click(find.tag('button'));

        // Then: onToggleRead が1回呼ばれる
        expect(count, equals(1));
      },
    );

    // T37
    testComponents(
      'should disable button and ignore clicks when isUpdating is true',
      (tester) async {
        // Given: isUpdating: true の ArticleCard とカウンタ付き onToggleRead
        var count = 0;
        tester.pumpComponent(
          ArticleCard(
            item: unreadItemA,
            isUpdating: true,
            onToggleRead: () => count++,
          ),
        );

        // When: ボタンをクリックする
        await tester.click(find.tag('button'));

        // Then: button に disabled 属性が付き、カウンタが 0 のまま
        expect(
          find.byComponentPredicate(
            (c) =>
                c is DomComponent &&
                c.tag == 'button' &&
                (c.attributes?.containsKey('disabled') ?? false),
          ),
          findsOneComponent,
        );
        expect(count, equals(0));
      },
    );
  });
}
