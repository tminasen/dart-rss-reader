import 'dart:convert';

import 'package:shared/shared.dart';

/// WebSocket で受信したメッセージを [ArticleItem] として読む。
///
/// 読めない場合は例外を投げず null を返す。
ArticleItem? parseNewArticleMessage(String message) {
  try {
    return ArticleItem.fromJson(jsonDecode(message) as Map<String, dynamic>);
  } on Object {
    return null;
  }
}
