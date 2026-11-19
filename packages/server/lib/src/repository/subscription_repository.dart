import 'package:shared/shared.dart';

import 'subscription.dart';

/// 購読フィードの保存先。
abstract interface class SubscriptionRepository {
  /// [feedUrl] を購読として登録する。ID はリポジトリが採番する。
  Future<Subscription> add(String feedUrl);

  /// [id] の購読を返す。なければ null。
  Future<Subscription?> findById(String id);

  /// [feedUrl] の購読を返す。なければ null。
  Future<Subscription?> findByUrl(String feedUrl);

  /// 登録順に全件を返す。
  Future<List<Subscription>> findAll();

  /// [id] の購読に、取得したフィード情報と取得日時を記録する。
  /// 購読が存在しなければ [SubscriptionNotFoundException] を投げる。
  Future<Subscription> updateFetched(
    String id, {
    required Feed feed,
    required DateTime fetchedAt,
  });
}
