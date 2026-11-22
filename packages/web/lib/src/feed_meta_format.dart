/// FeedInfo のメタ情報を「最終取得 YYYY/MM/DD HH:mm ・ 全N件」の形式に整形する。
///
/// [lastFetchedAt] はローカル時刻に変換して表示する。null なら「未取得」と出す。
String formatFeedMeta({
  required DateTime? lastFetchedAt,
  required int articleCount,
}) {
  final fetched = lastFetchedAt == null
      ? '未取得'
      : _formatDateTime(lastFetchedAt.toLocal());
  return '最終取得 $fetched ・ 全$articleCount件';
}

String _formatDateTime(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}/${_two(t.month)}/${_two(t.day)} '
    '${_two(t.hour)}:${_two(t.minute)}';

String _two(int n) => n.toString().padLeft(2, '0');
