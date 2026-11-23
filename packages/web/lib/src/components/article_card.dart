import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shared/shared.dart';

import '../article_view_helpers.dart';
import '../theme.dart';

/// 1件の記事カードを描画する。
class ArticleCard extends StatelessComponent {
  const ArticleCard({
    required this.item,
    required this.onToggleRead,
    this.isUpdating = false,
    this.isNew = false,
    super.key,
  });

  final ArticleItem item;
  final VoidCallback onToggleRead;
  final bool isUpdating;

  /// 受信したばかりの新着として強調表示するか。
  final bool isNew;

  @override
  Component build(BuildContext context) {
    final thumbnailUrl = extractThumbnailUrl(item.article);
    final link = safeArticleLink(item.article);
    final titleText = displayArticleTitle(item.article);
    final dateText = formatArticleDate(item.article);

    return article(
      styles: Styles(
        backgroundColor: isNew ? bgLightYellow : bgWhite,
        border: const Border.all(color: borderBlack, width: Unit.pixels(1)),
        radius: const BorderRadius.circular(Unit.pixels(8)),
        padding: const Padding.all(Unit.pixels(16)),
        display: Display.flex,
        alignItems: AlignItems.center,
        gap: const Gap.all(Unit.pixels(16)),
      ),
      [
        _buildThumbnail(thumbnailUrl),
        div(
          styles: const Styles(
            flex: Flex(grow: 1, shrink: 1, basis: Unit.zero),
            minWidth: Unit.zero,
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: Gap.all(Unit.pixels(6)),
            alignItems: AlignItems.start,
          ),
          [_buildTitle(titleText, link), _buildMeta(dateText)],
        ),
        button(
          type: ButtonType.button,
          disabled: isUpdating,
          onClick: isUpdating ? null : onToggleRead,
          styles: Styles(
            backgroundColor: bgWhite,
            border: const Border.all(color: borderBlack, width: Unit.pixels(1)),
            radius: const BorderRadius.circular(Unit.pixels(6)),
            padding: const Padding.symmetric(
              vertical: Unit.pixels(8),
              horizontal: Unit.pixels(14),
            ),
            fontSize: const Unit.pixels(13),
            fontWeight: FontWeight.w500,
            color: textBlack,
            lineHeight: lineHeightBase,
            whiteSpace: WhiteSpace.noWrap,
            flex: const Flex.shrink(0),
            cursor: isUpdating ? Cursor.defaultCursor : Cursor.pointer,
            fontFamily: notoSansJp,
          ),
          [Component.text(item.isRead ? '未読に戻す' : '既読にする')],
        ),
      ],
    );
  }

  Component _buildThumbnail(String? thumbnailUrl) {
    return div(
      styles: const Styles(
        width: Unit.pixels(120),
        height: Unit.pixels(68),
        radius: BorderRadius.circular(Unit.pixels(4)),
        backgroundColor: bgGray,
        flex: Flex.shrink(0),
      ),
      [
        if (thumbnailUrl != null)
          img(
            src: thumbnailUrl,
            alt: '',
            styles: const Styles(
              width: Unit.pixels(120),
              height: Unit.pixels(68),
              radius: BorderRadius.circular(Unit.pixels(4)),
              display: Display.block,
              raw: {'object-fit': 'cover'},
            ),
          ),
      ],
    );
  }

  Component _buildTitle(String titleText, String? link) {
    return h3(
      styles: Styles(
        margin: Margin.zero,
        fontSize: const Unit.pixels(16),
        fontWeight: FontWeight.bold,
        lineHeight: lineHeightBase,
        color: item.isRead ? textSubGray : textBlack,
      ),
      [
        if (link != null)
          a(
            href: link,
            target: Target.blank,
            attributes: const {'rel': 'noopener noreferrer'},
            styles: const Styles(
              color: Color.inherit,
              textDecoration: TextDecoration.none,
            ),
            [Component.text(titleText)],
          )
        else
          Component.text(titleText),
      ],
    );
  }

  Component _buildMeta(String? dateText) {
    return div(
      styles: const Styles(
        display: Display.flex,
        gap: Gap.all(Unit.pixels(8)),
        alignItems: AlignItems.center,
      ),
      [
        if (isNew)
          span(
            styles: const Styles(
              backgroundColor: bgBlack,
              radius: BorderRadius.circular(Unit.pixels(999)),
              padding: Padding.symmetric(
                vertical: Unit.pixels(2),
                horizontal: Unit.pixels(10),
              ),
              fontSize: Unit.pixels(11),
              fontWeight: FontWeight.bold,
              color: textWhite,
              lineHeight: lineHeightBase,
            ),
            [Component.text('NEW')],
          ),
        if (!item.isRead)
          span(
            styles: const Styles(
              backgroundColor: bgBlue,
              radius: BorderRadius.circular(Unit.pixels(999)),
              padding: Padding.symmetric(
                vertical: Unit.pixels(2),
                horizontal: Unit.pixels(10),
              ),
              fontSize: Unit.pixels(11),
              fontWeight: FontWeight.bold,
              color: textWhite,
              lineHeight: lineHeightBase,
            ),
            [Component.text('未読')],
          )
        else
          span(
            styles: const Styles(
              fontSize: Unit.pixels(12),
              fontWeight: FontWeight.w500,
              color: textSubGray,
              lineHeight: lineHeightBase,
            ),
            [Component.text('既読')],
          ),
        if (dateText != null)
          span(
            styles: const Styles(
              fontSize: Unit.pixels(12),
              fontWeight: FontWeight.normal,
              color: textSubGray,
              lineHeight: lineHeightBase,
            ),
            [Component.text(dateText)],
          ),
      ],
    );
  }
}
