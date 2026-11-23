import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:shared/shared.dart';
import 'package:web_app/src/api/api_exception.dart';
import 'package:web_app/src/components/article_list_section.dart';
import 'package:web_app/src/components/filter_tabs.dart';

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

final atomArticleA = AtomArticle(
  id: 'atom-1',
  title: 'Atom記事',
  link: 'https://example.com/atom/1',
  published: DateTime(2026, 1, 5),
  updated: DateTime(2026, 1, 6),
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

final unreadItemC = ArticleItem(
  id: 'a-3',
  feedId: 'f-1',
  isRead: false,
  article: atomArticleA,
);

Future<ArticleItem> unusedUpdate(String id, {required bool isRead}) async {
  throw UnimplementedError();
}

Finder buttonWithText(String label) =>
    find.ancestor(of: find.text(label), matching: find.tag('button'));

Finder toggleButtonForTitle(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.tag('article')),
  matching: find.tag('button'),
);

void main() {
  group('ArticleListSection', () {
    // T41
    testComponents(
      'should render 4 skeleton rows and no FilterTabs while initial load is pending',
      (tester) async {
        // Given: 未完了 Future を返す loadArticles
        Future<List<ArticleItem>> loadArticles() =>
            Completer<List<ArticleItem>>().future;

        // When: ArticleListSection を描画する
        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: unusedUpdate,
          ),
        );

        // Then: スケルトン行が4件描画され、FilterTabs は描画されない
        expect(
          find.byComponentPredicate(
            (c) =>
                c is DomComponent &&
                c.attributes?['data-testid'] == 'article-skeleton-row',
          ),
          findsNComponents(4),
        );
        expect(find.byType(FilterTabs), findsNothing);
      },
    );

    // T42
    testComponents(
      'should render FilterTabs and all article cards when load completes',
      (tester) async {
        // Given: 3件（未読2件）を返す loadArticles
        Future<List<ArticleItem>> loadArticles() async => [
          unreadItemA,
          readItemB,
          unreadItemC,
        ];

        // When: 描画し、Future の完了を待つ
        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: unusedUpdate,
          ),
        );
        await tester.pump();

        // Then: FilterTabs（「すべて 3」「未読 2」）と3件の記事タイトルがすべて描画される
        expect(find.text('すべて 3'), findsOneComponent);
        expect(find.text('未読 2'), findsOneComponent);
        expect(find.text('Angularを使ってボードゲームの得点計算ツールを作った話'), findsOneComponent);
        expect(
          find.text('styled-componentsからTailwindCSSに移行する際に困ったこと'),
          findsOneComponent,
        );
        expect(find.text('Atom記事'), findsOneComponent);
      },
    );

    // T43
    testComponents(
      'should show only unread articles on unread tab and restore all on all tab',
      (tester) async {
        // Given: 3件（未読2件）をロード済みの ArticleListSection
        Future<List<ArticleItem>> loadArticles() async => [
          unreadItemA,
          readItemB,
          unreadItemC,
        ];
        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: unusedUpdate,
          ),
        );
        await tester.pump();

        // When: 「未読 2」タブをクリックする
        await tester.click(buttonWithText('未読 2'));

        // Then: 未読の2件のみ描画され、既読の readItemB は非表示になる
        expect(find.text('Angularを使ってボードゲームの得点計算ツールを作った話'), findsOneComponent);
        expect(find.text('Atom記事'), findsOneComponent);
        expect(
          find.text('styled-componentsからTailwindCSSに移行する際に困ったこと'),
          findsNothing,
        );

        // When: 「すべて 3」タブをクリックする
        await tester.click(buttonWithText('すべて 3'));

        // Then: 3件すべてが再び描画される
        expect(find.text('Angularを使ってボードゲームの得点計算ツールを作った話'), findsOneComponent);
        expect(
          find.text('styled-componentsからTailwindCSSに移行する際に困ったこと'),
          findsOneComponent,
        );
        expect(find.text('Atom記事'), findsOneComponent);
      },
    );

    // T44
    testComponents(
      'should render FilterTabs (0/0) and empty state when articles list is empty',
      (tester) async {
        // Given: 空リストを返す loadArticles
        Future<List<ArticleItem>> loadArticles() async => [];

        // When: 描画し、Future の完了を待つ
        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: unusedUpdate,
          ),
        );
        await tester.pump();

        // Then: FilterTabs（「すべて 0」「未読 0」）と空状態の文言が描画される
        expect(find.text('すべて 0'), findsOneComponent);
        expect(find.text('未読 0'), findsOneComponent);
        expect(find.text('記事がありません'), findsOneComponent);
        expect(find.text('フィードの巡回が完了すると、ここに記事が表示されます。'), findsOneComponent);
      },
    );

    // T45
    testComponents(
      'should render unread empty state when all articles are read and unread tab is selected',
      (tester) async {
        // Given: 既読記事のみのリストをロード済みの ArticleListSection
        Future<List<ArticleItem>> loadArticles() async => [readItemB];
        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: unusedUpdate,
          ),
        );
        await tester.pump();

        // When: 「未読 0」タブをクリックする
        await tester.click(buttonWithText('未読 0'));

        // Then: 「未読の記事はありません」が描画され、readItemB は非表示になる
        expect(find.text('未読の記事はありません'), findsOneComponent);
        expect(
          find.text('styled-componentsからTailwindCSSに移行する際に困ったこと'),
          findsNothing,
        );
      },
    );

    // T46
    testComponents(
      'should update card and unread count when unread article is marked read on all tab',
      (tester) async {
        // Given: 3件（未読2件）ロード済み、updateArticleRead を記録するフェイク
        final calls = <(String, bool)>[];
        Future<List<ArticleItem>> loadArticles() async => [
          unreadItemA,
          readItemB,
          unreadItemC,
        ];
        Future<ArticleItem> updateRead(
          String id, {
          required bool isRead,
        }) async {
          calls.add((id, isRead));
          return ArticleItem(
            id: id,
            feedId: 'f-1',
            isRead: isRead,
            article: rssArticleA,
          );
        }

        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: updateRead,
          ),
        );
        await tester.pump();

        // When: unreadItemA の「既読にする」をクリックする
        await tester.click(
          toggleButtonForTitle('Angularを使ってボードゲームの得点計算ツールを作った話'),
        );
        await tester.pump();

        // Then: ('a-1', true) で1回呼ばれ、「すべて 3」「未読 1」になり、「未読に戻す」が2件になる
        expect(calls, equals([('a-1', true)]));
        expect(find.text('すべて 3'), findsOneComponent);
        expect(find.text('未読 1'), findsOneComponent);
        expect(find.text('未読に戻す'), findsNComponents(2));
      },
    );

    // T47
    testComponents(
      'should remove article from unread tab and decrease unread count when marked read',
      (tester) async {
        // Given: 3件（未読2件）ロード済みで「未読 2」タブ選択中
        Future<List<ArticleItem>> loadArticles() async => [
          unreadItemA,
          readItemB,
          unreadItemC,
        ];
        Future<ArticleItem> updateRead(
          String id, {
          required bool isRead,
        }) async {
          return ArticleItem(
            id: id,
            feedId: 'f-1',
            isRead: isRead,
            article: rssArticleA,
          );
        }

        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: updateRead,
          ),
        );
        await tester.pump();
        await tester.click(buttonWithText('未読 2'));

        // When: unreadItemA の「既読にする」をクリックする
        await tester.click(
          toggleButtonForTitle('Angularを使ってボードゲームの得点計算ツールを作った話'),
        );
        await tester.pump();

        // Then: unreadItemA が一覧から消え、unreadItemC のみ残り、「未読 1」になる
        expect(find.text('Angularを使ってボードゲームの得点計算ツールを作った話'), findsNothing);
        expect(find.text('Atom記事'), findsOneComponent);
        expect(find.text('未読 1'), findsOneComponent);
      },
    );

    // T48
    testComponents(
      'should mark read article unread and increase unread count when clicked',
      (tester) async {
        // Given: [unreadItemA, readItemB] ロード済み
        final calls = <(String, bool)>[];
        Future<List<ArticleItem>> loadArticles() async => [
          unreadItemA,
          readItemB,
        ];
        Future<ArticleItem> updateRead(
          String id, {
          required bool isRead,
        }) async {
          calls.add((id, isRead));
          return ArticleItem(
            id: id,
            feedId: 'f-1',
            isRead: isRead,
            article: rssArticleB,
          );
        }

        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: updateRead,
          ),
        );
        await tester.pump();

        // When: readItemB の「未読に戻す」をクリックする
        await tester.click(
          toggleButtonForTitle('styled-componentsからTailwindCSSに移行する際に困ったこと'),
        );
        await tester.pump();

        // Then: ('a-2', false) で1回呼ばれ、「未読 2」になり、「既読にする」が2件になる
        expect(calls, equals([('a-2', false)]));
        expect(find.text('未読 2'), findsOneComponent);
        expect(find.text('既読にする'), findsNComponents(2));
      },
    );

    // T49
    testComponents(
      'should call update API only once and disable button when clicked repeatedly during request',
      (tester) async {
        // Given: [unreadItemA] ロード済み、未完了 Completer を返す updateArticleRead
        var callCount = 0;
        final completer = Completer<ArticleItem>();
        Future<List<ArticleItem>> loadArticles() async => [unreadItemA];
        Future<ArticleItem> updateRead(String id, {required bool isRead}) {
          callCount++;
          return completer.future;
        }

        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: updateRead,
          ),
        );
        await tester.pump();

        // When: 「既読にする」を2回連続クリックする
        await tester.click(buttonWithText('既読にする'));
        await tester.click(buttonWithText('既読にする'));

        // Then: 呼び出し回数が 1 のままで、ボタンが disabled になる
        expect(callCount, equals(1));
        final btnDom =
            buttonWithText('既読にする').evaluate().single.component as DomComponent;
        expect(btnDom.attributes?.containsKey('disabled'), isTrue);
      },
    );

    // T50
    testComponents(
      'should preserve read state and show error banner when updateArticleRead fails',
      (tester) async {
        // Given: [unreadItemA] ロード済み、ApiConnectionException を投げる updateArticleRead
        Future<List<ArticleItem>> loadArticles() async => [unreadItemA];
        Future<ArticleItem> updateRead(
          String id, {
          required bool isRead,
        }) async {
          throw const ApiConnectionException('connection refused');
        }

        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: updateRead,
          ),
        );
        await tester.pump();

        // When: 「既読にする」をクリックする
        await tester.click(buttonWithText('既読にする'));
        await tester.pump();

        // Then: 未読状態と「未読 1」を維持し、エラーバナーと「再試行」ボタンが描画される
        expect(find.text('未読'), findsOneComponent);
        expect(find.text('既読にする'), findsOneComponent);
        expect(find.text('未読 1'), findsOneComponent);
        expect(find.text('既読状態の更新に失敗しました。'), findsOneComponent);
        expect(buttonWithText('再試行'), findsOneComponent);
      },
    );

    // T51
    testComponents(
      'should show error banner on initial fetch failure and recover on retry',
      (tester) async {
        // Given: 1回目は ApiConnectionException、2回目は [unreadItemA] を返す loadArticles
        var attempt = 0;
        Future<List<ArticleItem>> loadArticles() async {
          attempt++;
          if (attempt == 1) {
            throw const ApiConnectionException('connection refused');
          }
          return [unreadItemA];
        }

        // When: 描画し1回目の完了を待つ
        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: unusedUpdate,
          ),
        );
        await tester.pump();

        // Then: 「記事を取得できませんでした。」と「再試行」が描画される
        expect(find.text('記事を取得できませんでした。'), findsOneComponent);
        expect(buttonWithText('再試行'), findsOneComponent);

        // When: 「再試行」をクリックし、2回目の完了を待つ
        await tester.click(buttonWithText('再試行'));
        await tester.pump();

        // Then: エラーバナーが消え unreadItemA が描画される
        expect(find.text('記事を取得できませんでした。'), findsNothing);
        expect(find.text('Angularを使ってボードゲームの得点計算ツールを作った話'), findsOneComponent);
      },
    );

    // T52
    testComponents(
      'should keep previous articles and show error banner when refetch fails after articles were loaded',
      (tester) async {
        // Given: 1回目は [readItemB]、既読更新失敗後の再試行で呼ばれる2回目の loadArticles は失敗する
        var attempt = 0;
        Future<List<ArticleItem>> loadArticles() async {
          attempt++;
          if (attempt == 1) return [readItemB];
          throw const ApiConnectionException('connection refused');
        }

        Future<ArticleItem> failingUpdate(
          String id, {
          required bool isRead,
        }) async {
          throw const ApiConnectionException('connection refused');
        }

        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: failingUpdate,
          ),
        );
        await tester.pump();

        // When: 「未読に戻す」失敗後に「再試行」をクリックする
        await tester.click(buttonWithText('未読に戻す'));
        await tester.pump();
        await tester.click(buttonWithText('再試行'));
        await tester.pump();

        // Then: 前回記事カードを残したまま専用エラーバナーと「再試行」が表示される
        expect(
          find.text('フィードを取得できませんでした。前回取得した記事を表示しています。'),
          findsOneComponent,
        );
        expect(buttonWithText('再試行'), findsOneComponent);
        expect(
          find.text('styled-componentsからTailwindCSSに移行する際に困ったこと'),
          findsOneComponent,
        );
      },
    );

    // T54
    testComponents(
      'should preserve read update completed during refetch when loadArticles completes later',
      (tester) async {
        // Given: 初回 loadArticles は [unreadItemA, readItemB] を返し、再試行時の2回目は
        //       未完了の Completer で遅延して古い [unreadItemA, readItemB] を返す。
        //       updateArticleRead は a-1 で失敗し、別記事 a-2 で未読化成功する
        var loadAttempt = 0;
        final refetchCompleter = Completer<List<ArticleItem>>();
        Future<List<ArticleItem>> loadArticles() {
          loadAttempt++;
          if (loadAttempt == 1) {
            return Future.value([unreadItemA, readItemB]);
          }
          return refetchCompleter.future;
        }

        Future<ArticleItem> updateRead(
          String id, {
          required bool isRead,
        }) async {
          if (id == 'a-1') {
            throw const ApiConnectionException('connection refused');
          }
          return ArticleItem(
            id: id,
            feedId: 'f-1',
            isRead: isRead,
            article: rssArticleB,
          );
        }

        tester.pumpComponent(
          ArticleListSection(
            loadArticles: loadArticles,
            updateArticleRead: updateRead,
          ),
        );
        await tester.pump();

        // a-1 の既読更新を失敗させて「再試行」ボタンを表示し、再取得を開始する
        await tester.click(
          toggleButtonForTitle('Angularを使ってボードゲームの得点計算ツールを作った話'),
        );
        await tester.pump();
        await tester.click(buttonWithText('再試行'));

        // When: 再取得完了前に別記事 readItemB (a-2) を「未読に戻す」で更新し、
        //       その後で後着の loadArticles が古いスナップショットを返す
        await tester.click(
          toggleButtonForTitle('styled-componentsからTailwindCSSに移行する際に困ったこと'),
        );
        await tester.pump();
        refetchCompleter.complete([unreadItemA, readItemB]);
        await tester.pump();

        // Then: a-2 の未読化が後着の loadArticles 結果で上書きされず維持される
        expect(find.text('未読 2'), findsOneComponent);
        expect(find.text('既読にする'), findsNComponents(2));
        expect(find.text('未読に戻す'), findsNothing);
      },
    );
  });
}
