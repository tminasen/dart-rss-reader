import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shared/shared.dart';

import '../article_view_helpers.dart';
import '../theme.dart';
import 'article_card.dart';
import 'filter_tabs.dart';

/// 記事一覧の状態（読み込み・絞り込み・既読切替・エラー復帰）を管理して描画する。
class ArticleListSection extends StatefulComponent {
  const ArticleListSection({
    required this.loadArticles,
    required this.updateArticleRead,
    this.newArticles,
    super.key,
  });

  final Future<List<ArticleItem>> Function() loadArticles;
  final Future<ArticleItem> Function(String id, {required bool isRead})
  updateArticleRead;

  /// 受信した新着記事のストリーム。省略時は新着を扱わない。
  final Stream<ArticleItem>? newArticles;

  @override
  State<ArticleListSection> createState() => _ArticleListSectionState();
}

class _ArticleListSectionState extends State<ArticleListSection> {
  List<ArticleItem>? _articles;
  ArticleFilter _selectedFilter = ArticleFilter.all;
  final Set<String> _updatingIds = {};
  final Map<String, ArticleItem> _overridesDuringLoad = {};
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _newIds = {};
  final List<ArticleItem> _pendingNew = [];
  int _receivedCount = 0;
  StreamSubscription<ArticleItem>? _newArticlesSubscription;

  @override
  void initState() {
    super.initState();
    _newArticlesSubscription = component.newArticles?.listen(_onNewArticle);
    _load();
  }

  @override
  void dispose() {
    _newArticlesSubscription?.cancel();
    super.dispose();
  }

  void _onNewArticle(ArticleItem item) {
    if (!mounted) return;
    if (_isLoading) {
      // 読み込みの結果で一覧が置き換わるため、完了後にまとめて反映する。
      _pendingNew.add(item);
      return;
    }
    final articles = _articles;
    if (articles == null) return;
    setState(() {
      _articles = _withNewArticle(articles, item);
    });
  }

  /// 一覧にない [item] を NEW として先頭に加え、受信件数に数える。
  List<ArticleItem> _withNewArticle(
    List<ArticleItem> articles,
    ArticleItem item,
  ) {
    final updated = prependIfAbsent(articles, item);
    if (updated.length != articles.length) {
      _newIds.add(item.id);
      _receivedCount++;
    }
    return updated;
  }

  /// 読み込み中に受信した新着を [articles] の先頭へ反映する。
  List<ArticleItem> _withPendingNewArticles(List<ArticleItem> articles) {
    var result = articles;
    for (final item in _pendingNew) {
      result = _withNewArticle(result, item);
    }
    _pendingNew.clear();
    return result;
  }

  void _retry() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _load();
  }

  Future<void> _load() async {
    _overridesDuringLoad.clear();
    try {
      final fetched = await component.loadArticles();
      if (!mounted) return;
      setState(() {
        _articles = _withPendingNewArticles([
          for (final item in fetched) _overridesDuringLoad[item.id] ?? item,
        ]);
        _overridesDuringLoad.clear();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final articles = _articles;
        if (articles != null) {
          _articles = _withPendingNewArticles(articles);
        }
        _overridesDuringLoad.clear();
        _isLoading = false;
        _errorMessage = _articles == null
            ? '記事を取得できませんでした。'
            : 'フィードを取得できませんでした。前回取得した記事を表示しています。';
      });
    }
  }

  Future<void> _toggleRead(ArticleItem item) async {
    if (_updatingIds.contains(item.id)) return;
    setState(() {
      _updatingIds.add(item.id);
    });
    try {
      final updated = await component.updateArticleRead(
        item.id,
        isRead: !item.isRead,
      );
      if (!mounted) return;
      setState(() {
        _updatingIds.remove(item.id);
        if (_isLoading) {
          _overridesDuringLoad[updated.id] = updated;
        }
        final articles = _articles;
        if (articles != null) {
          _articles = [
            for (final current in articles)
              if (current.id == updated.id) updated else current,
          ];
        }
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _updatingIds.remove(item.id);
        _errorMessage = '既読状態の更新に失敗しました。';
      });
    }
  }

  @override
  Component build(BuildContext context) {
    final articles = _articles;
    final errorMessage = _errorMessage;

    if (articles == null) {
      return section(
        styles: const Styles(
          display: Display.flex,
          flexDirection: FlexDirection.column,
          gap: Gap.all(Unit.pixels(12)),
        ),
        [
          if (errorMessage != null && !_isLoading)
            _ErrorBanner(message: errorMessage, onRetry: _retry)
          else
            for (var i = 0; i < 4; i++) const _SkeletonRow(),
        ],
      );
    }

    final filtered = filterArticles(articles, _selectedFilter);
    final unreadCount = countUnread(articles);

    return section(
      styles: const Styles(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: Gap.all(Unit.pixels(12)),
      ),
      [
        if (errorMessage != null)
          _ErrorBanner(message: errorMessage, onRetry: _retry),
        FilterTabs(
          selected: _selectedFilter,
          allCount: articles.length,
          unreadCount: unreadCount,
          onSelect: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
        ),
        if (_receivedCount > 0) _NewArticlesBanner(count: _receivedCount),
        if (articles.isEmpty)
          const _EmptyState(
            heading: '記事がありません',
            body: 'フィードの巡回が完了すると、ここに記事が表示されます。',
          )
        else if (filtered.isEmpty)
          const _EmptyState(heading: '未読の記事はありません')
        else
          div(
            styles: const Styles(
              display: Display.flex,
              flexDirection: FlexDirection.column,
              gap: Gap.all(Unit.pixels(12)),
            ),
            [
              for (final item in filtered)
                ArticleCard(
                  key: ValueKey<String>(item.id),
                  item: item,
                  isUpdating: _updatingIds.contains(item.id),
                  isNew: _newIds.contains(item.id),
                  onToggleRead: () => _toggleRead(item),
                ),
            ],
          ),
      ],
    );
  }
}

class _NewArticlesBanner extends StatelessComponent {
  const _NewArticlesBanner({required this.count});

  final int count;

  @override
  Component build(BuildContext context) {
    return div(
      styles: const Styles(
        backgroundColor: bgLightYellow,
        border: Border.all(color: borderBlack, width: Unit.pixels(1)),
        radius: BorderRadius.circular(Unit.pixels(8)),
        padding: Padding.symmetric(
          vertical: Unit.pixels(12),
          horizontal: Unit.pixels(16),
        ),
      ),
      [
        p(
          styles: const Styles(
            margin: Margin.zero,
            fontSize: Unit.pixels(14),
            fontWeight: FontWeight.w500,
            color: textBlack,
            lineHeight: lineHeightBase,
          ),
          [Component.text('新着記事を$count件受信しました')],
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessComponent {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Component build(BuildContext context) {
    return div(
      styles: const Styles(
        backgroundColor: bgRed,
        border: Border.all(color: borderBlack, width: Unit.pixels(1)),
        radius: BorderRadius.circular(Unit.pixels(8)),
        padding: Padding.symmetric(
          vertical: Unit.pixels(12),
          horizontal: Unit.pixels(16),
        ),
        display: Display.flex,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.spaceBetween,
        gap: Gap.all(Unit.pixels(16)),
      ),
      [
        p(
          styles: const Styles(
            margin: Margin.zero,
            fontSize: Unit.pixels(14),
            fontWeight: FontWeight.w500,
            color: textWhite,
            lineHeight: lineHeightBase,
          ),
          [Component.text(message)],
        ),
        button(
          type: ButtonType.button,
          onClick: onRetry,
          styles: const Styles(
            backgroundColor: bgWhite,
            border: Border.all(color: borderBlack, width: Unit.pixels(1)),
            radius: BorderRadius.circular(Unit.pixels(6)),
            padding: Padding.symmetric(
              vertical: Unit.pixels(8),
              horizontal: Unit.pixels(14),
            ),
            fontSize: Unit.pixels(13),
            fontWeight: FontWeight.w500,
            color: textBlack,
            lineHeight: lineHeightBase,
            whiteSpace: WhiteSpace.noWrap,
            flex: Flex.shrink(0),
            cursor: Cursor.pointer,
            fontFamily: notoSansJp,
          ),
          [Component.text('再試行')],
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessComponent {
  const _SkeletonRow();

  @override
  Component build(BuildContext context) {
    return div(
      attributes: const {'data-testid': 'article-skeleton-row'},
      styles: const Styles(
        backgroundColor: bgWhite,
        border: Border.all(color: borderBlack, width: Unit.pixels(1)),
        radius: BorderRadius.circular(Unit.pixels(8)),
        padding: Padding.all(Unit.pixels(16)),
        display: Display.flex,
        alignItems: AlignItems.center,
        gap: Gap.all(Unit.pixels(16)),
      ),
      [
        div(
          styles: const Styles(
            width: Unit.pixels(120),
            height: Unit.pixels(68),
            backgroundColor: bgGray,
            radius: BorderRadius.circular(Unit.pixels(4)),
            flex: Flex.shrink(0),
          ),
          [],
        ),
        div(
          styles: const Styles(
            flex: Flex(grow: 1, shrink: 1, basis: Unit.zero),
            minWidth: Unit.zero,
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: Gap.all(Unit.pixels(10)),
          ),
          [
            div(
              styles: const Styles(
                height: Unit.pixels(16),
                maxWidth: Unit.pixels(520),
                width: Unit.percent(100),
                backgroundColor: bgGray,
                radius: BorderRadius.circular(Unit.pixels(4)),
              ),
              [],
            ),
            div(
              styles: const Styles(
                height: Unit.pixels(12),
                width: Unit.pixels(160),
                backgroundColor: bgGray,
                radius: BorderRadius.circular(Unit.pixels(4)),
              ),
              [],
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessComponent {
  const _EmptyState({required this.heading, this.body});

  final String heading;
  final String? body;

  @override
  Component build(BuildContext context) {
    return div(
      styles: const Styles(
        backgroundColor: bgWhite,
        border: Border.all(color: borderBlack, width: Unit.pixels(1)),
        radius: BorderRadius.circular(Unit.pixels(8)),
        padding: Padding.symmetric(
          vertical: Unit.pixels(64),
          horizontal: Unit.pixels(32),
        ),
        display: Display.flex,
        flexDirection: FlexDirection.column,
        alignItems: AlignItems.center,
        gap: Gap.all(Unit.pixels(8)),
        lineHeight: lineHeightBase,
      ),
      [
        p(
          styles: const Styles(
            margin: Margin.zero,
            fontSize: Unit.pixels(18),
            fontWeight: FontWeight.bold,
            color: textBlack,
          ),
          [Component.text(heading)],
        ),
        if (body != null)
          p(
            styles: const Styles(
              margin: Margin.zero,
              fontSize: Unit.pixels(13),
              fontWeight: FontWeight.normal,
              color: textSubGray,
            ),
            [Component.text(body!)],
          ),
      ],
    );
  }
}
