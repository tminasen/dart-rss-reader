import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shared/shared.dart';

import '../feed_meta_format.dart';
import '../theme.dart';

class FeedInfo extends StatelessComponent {
  const FeedInfo({required this.summary, super.key});

  final FeedSummary summary;

  @override
  Component build(BuildContext context) {
    return section(
      styles: const Styles(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: Gap.all(Unit.pixels(4)),
        backgroundColor: bgWhite,
        border: Border.all(color: borderBlack, width: Unit.pixels(1)),
        radius: BorderRadius.circular(Unit.pixels(8)),
        padding: Padding.all(Unit.pixels(20)),
        lineHeight: lineHeightBase,
      ),
      [
        h2(
          styles: const Styles(
            margin: Margin.zero,
            fontSize: Unit.pixels(20),
            fontWeight: FontWeight.bold,
            color: textBlack,
          ),
          [Component.text(summary.title ?? 'タイトル未取得')],
        ),
        p(
          styles: const Styles(
            margin: Margin.zero,
            fontSize: Unit.pixels(13),
            fontWeight: FontWeight.normal,
            color: textSubGray,
          ),
          [Component.text(summary.url)],
        ),
        p(
          styles: const Styles(
            margin: Margin.zero,
            fontSize: Unit.pixels(12),
            fontWeight: FontWeight.normal,
            color: textSubGray,
          ),
          [
            Component.text(
              formatFeedMeta(
                lastFetchedAt: summary.lastFetchedAt,
                articleCount: summary.articleCount,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
