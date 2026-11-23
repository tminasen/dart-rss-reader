import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shared/shared.dart';

import 'src/components/article_list_section.dart';
import 'src/components/feed_info_section.dart';
import 'src/components/header.dart';
import 'src/theme.dart';

class App extends StatelessComponent {
  const App({
    required this.loadFeeds,
    required this.loadArticles,
    required this.updateArticleRead,
    super.key,
  });

  final Future<List<FeedSummary>> Function() loadFeeds;
  final Future<List<ArticleItem>> Function() loadArticles;
  final Future<ArticleItem> Function(String id, {required bool isRead})
  updateArticleRead;

  @override
  Component build(BuildContext context) {
    return div(
      styles: const Styles(
        minHeight: Unit.vh(100),
        backgroundColor: bgLightGray,
      ),
      [
        const Header(),
        main_(
          styles: const Styles(
            maxWidth: Unit.pixels(880),
            margin: Margin.symmetric(horizontal: Unit.auto),
            padding: Padding.symmetric(vertical: Unit.pixels(32)),
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: Gap.all(Unit.pixels(20)),
          ),
          [
            FeedInfoSection(loadFeeds: loadFeeds),
            ArticleListSection(
              loadArticles: loadArticles,
              updateArticleRead: updateArticleRead,
            ),
          ],
        ),
      ],
    );
  }
}
