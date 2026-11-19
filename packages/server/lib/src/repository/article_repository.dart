import 'package:shared/shared.dart';

import 'stored_article.dart';

/// 記事の保存先。
abstract interface class ArticleRepository {
  /// [articles] を [feedId] のフィードの記事として保存する。
  ///
  /// 同一フィード内で一意キー（RSS は guid、なければ link／Atom は id）が
  /// 重複する記事と、キーが作れない記事は保存しない。
  /// 空文字の guid / link は、ないものとして扱う。
  /// 戻り値は実際に保存された記事で、入力順に並ぶ。
  Future<List<StoredArticle>> addAll(String feedId, List<Article> articles);

  /// [id] の記事を返す。なければ null。
  Future<StoredArticle?> findById(String id);

  /// 記事を基準日時の新しい順に返す。
  ///
  /// [feedId] を指定するとそのフィードの記事だけ、[unreadOnly] が true なら
  /// 未読だけに絞り込む。[limit] が null なら全件。
  /// [limit] が 1 未満、または [offset] が負なら [ArgumentError] を投げる。
  Future<List<StoredArticle>> find({
    String? feedId,
    bool unreadOnly = false,
    int? limit,
    int offset = 0,
  });

  /// [id] の記事の既読状態を [isRead] にする。
  /// 記事が存在しなければ [ArticleNotFoundException] を投げる。
  Future<StoredArticle> setRead(String id, {required bool isRead});
}
