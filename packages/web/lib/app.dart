import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shared/shared.dart';

import 'src/components/feed_info_section.dart';
import 'src/components/header.dart';
import 'src/theme.dart';

class App extends StatelessComponent {
  const App({required this.loadFeeds, super.key});

  final Future<List<FeedSummary>> Function() loadFeeds;

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
            padding: Padding.only(top: Unit.pixels(32)),
          ),
          [FeedInfoSection(loadFeeds: loadFeeds)],
        ),
      ],
    );
  }
}
