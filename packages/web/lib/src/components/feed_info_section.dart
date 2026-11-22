import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shared/shared.dart';

import '../theme.dart';
import 'feed_info.dart';

/// フィード一覧を読み込み、先頭のフィードを [FeedInfo] で表示する。
///
/// 読み込み中・0件・失敗のときは、それぞれ文言を表示する。
class FeedInfoSection extends StatefulComponent {
  const FeedInfoSection({required this.loadFeeds, super.key});

  final Future<List<FeedSummary>> Function() loadFeeds;

  @override
  State<FeedInfoSection> createState() => _FeedInfoSectionState();
}

class _FeedInfoSectionState extends State<FeedInfoSection> {
  late final Future<List<FeedSummary>> _feeds;

  @override
  void initState() {
    super.initState();
    _feeds = component.loadFeeds();
  }

  @override
  Component build(BuildContext context) {
    return FutureBuilder<List<FeedSummary>>(
      future: _feeds,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _Message('フィード情報を取得できませんでした');
        }
        final feeds = snapshot.data;
        if (feeds == null) {
          return const _Message('読み込み中…');
        }
        if (feeds.isEmpty) {
          return const _Message('購読中のフィードがありません');
        }
        return FeedInfo(summary: feeds.first);
      },
    );
  }
}

class _Message extends StatelessComponent {
  const _Message(this.text);

  final String text;

  @override
  Component build(BuildContext context) {
    return p(
      styles: const Styles(
        margin: Margin.zero,
        fontSize: Unit.pixels(13),
        color: textSubGray,
      ),
      [Component.text(text)],
    );
  }
}
