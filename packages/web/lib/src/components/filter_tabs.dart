import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../article_view_helpers.dart';
import '../theme.dart';

/// 記事一覧の絞り込みタブ（「すべて」「未読」）を描画する。
class FilterTabs extends StatelessComponent {
  const FilterTabs({
    required this.selected,
    required this.allCount,
    required this.unreadCount,
    required this.onSelect,
    super.key,
  });

  final ArticleFilter selected;
  final int allCount;
  final int unreadCount;
  final void Function(ArticleFilter filter) onSelect;

  @override
  Component build(BuildContext context) {
    return div(
      styles: const Styles(display: Display.flex, gap: Gap.all(Unit.pixels(8))),
      [
        _buildTab(ArticleFilter.all, 'すべて $allCount'),
        _buildTab(ArticleFilter.unread, '未読 $unreadCount'),
      ],
    );
  }

  Component _buildTab(ArticleFilter filter, String label) {
    final isSelected = selected == filter;
    return button(
      type: ButtonType.button,
      onClick: () => onSelect(filter),
      attributes: {'aria-pressed': isSelected ? 'true' : 'false'},
      styles: Styles(
        padding: const Padding.symmetric(
          vertical: Unit.pixels(6),
          horizontal: Unit.pixels(14),
        ),
        radius: const BorderRadius.circular(Unit.pixels(999)),
        fontSize: const Unit.pixels(11),
        fontWeight: FontWeight.bold,
        lineHeight: lineHeightBase,
        cursor: Cursor.pointer,
        fontFamily: notoSansJp,
        border: const Border.all(color: borderBlack, width: Unit.pixels(1)),
        backgroundColor: isSelected ? bgBlack : bgWhite,
        color: isSelected ? textWhite : textBlack,
      ),
      [Component.text(label)],
    );
  }
}
