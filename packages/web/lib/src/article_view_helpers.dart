import 'package:shared/shared.dart';

/// 記事の公開日時をローカル時刻の `YYYY/MM/DD` 形式に整形する。
///
/// 日時が存在しない場合（[RssArticle.pubDate] が null）は null を返す。
String? formatArticleDate(Article article) {
  final date = switch (article) {
    RssArticle(:final pubDate) => pubDate,
    AtomArticle(:final published, :final updated) => published ?? updated,
  };
  if (date == null) return null;
  final local = date.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year/$month/$day';
}

/// 記事のサムネイル画像 URL を抽出する。
///
/// [RssArticle.enclosure] が `image/*` かつ http/https URL のときのみ返し、
/// それ以外は null を返す。
String? extractThumbnailUrl(Article article) {
  if (article is! RssArticle) return null;
  final enclosure = article.enclosure;
  if (enclosure == null) return null;
  if (!enclosure.type.toLowerCase().startsWith('image/')) return null;
  return _safeHttpUrl(enclosure.url);
}

String? _safeHttpUrl(String? raw) {
  if (raw == null) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  if (uri.host.isEmpty) return null;
  return raw;
}

/// 記事一覧の表示フィルタ。
enum ArticleFilter { all, unread }

/// 記事リンクが安全な http/https URL であれば返し、それ以外は null を返す。
String? safeArticleLink(Article article) => _safeHttpUrl(article.link);

/// 表示用の記事タイトルを返す。null または空白のみなら「無題の記事」。
String displayArticleTitle(Article article) {
  final title = article.title;
  if (title == null || title.trim().isEmpty) return '無題の記事';
  return title;
}

/// 選択中の [filter] に応じて記事リストを絞り込む。
List<ArticleItem> filterArticles(
  List<ArticleItem> articles,
  ArticleFilter filter,
) {
  return switch (filter) {
    ArticleFilter.all => List<ArticleItem>.of(articles),
    ArticleFilter.unread => [
      for (final item in articles)
        if (!item.isRead) item,
    ],
  };
}

/// 未読記事の件数を返す。
int countUnread(List<ArticleItem> articles) =>
    articles.where((item) => !item.isRead).length;
