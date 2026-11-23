import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shared/shared.dart';

import 'src/components/article_list_section.dart';
import 'src/components/feed_info_section.dart';
import 'src/components/header.dart';
import 'src/realtime/connection_status.dart';
import 'src/theme.dart';

class App extends StatelessComponent {
  const App({
    required this.loadFeeds,
    required this.loadArticles,
    required this.updateArticleRead,
    this.newArticles,
    this.connectionStatus,
    super.key,
  });

  final Future<List<FeedSummary>> Function() loadFeeds;
  final Future<List<ArticleItem>> Function() loadArticles;
  final Future<ArticleItem> Function(String id, {required bool isRead})
  updateArticleRead;
  final Stream<ArticleItem>? newArticles;
  final ValueListenable<ConnectionStatus>? connectionStatus;

  @override
  Component build(BuildContext context) {
    final connectionStatus = this.connectionStatus;
    return div(
      styles: const Styles(
        minHeight: Unit.vh(100),
        backgroundColor: bgLightGray,
      ),
      [
        if (connectionStatus == null)
          const Header()
        else
          ValueListenableBuilder<ConnectionStatus>(
            listenable: connectionStatus,
            builder: (context, status) => Header(connectionStatus: status),
          ),
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
              newArticles: newArticles,
            ),
          ],
        ),
      ],
    );
  }
}
