import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'repository/stored_article.dart';

/// 接続したクライアントへ、[newArticles] に流れた新着記事を JSON で送る。
///
/// Origin ヘッダーを持つ接続は、[allowedOrigins] に含まれない場合に拒否する
/// （Origin ヘッダーのない接続は許可する）。
Handler newArticlesSocketHandler(
  Stream<StoredArticle> newArticles, {
  Set<String> allowedOrigins = const {},
}) {
  return webSocketHandler(allowedOrigins: allowedOrigins, (channel, _) {
    final subscription = newArticles.listen(
      (stored) => channel.sink.add(jsonEncode(stored.toJson())),
    );
    // クライアントからのメッセージは無視する。切断（終了・エラー）で購読を解除する。
    channel.stream.listen(
      null,
      onError: (Object _) => subscription.cancel(),
      onDone: subscription.cancel,
    );
  });
}
