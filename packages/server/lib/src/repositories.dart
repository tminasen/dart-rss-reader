import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'default_subscription_repository.dart';
import 'repository/article_repository.dart';
import 'repository/in_memory_article_repository.dart';
import 'repository/sqlite_article_repository.dart';
import 'repository/sqlite_schema.dart';
import 'repository/sqlite_subscription_repository.dart';
import 'repository/subscription_repository.dart';
import 'repository_config.dart';

/// 組み立てたリポジトリと、使い終わったときに呼ぶ [close]。
final class Repositories {
  const Repositories({
    required this.subscriptions,
    required this.articles,
    required this.close,
  });

  final SubscriptionRepository subscriptions;
  final ArticleRepository articles;
  final void Function() close;
}

/// [config] に従ってリポジトリを組み立て、[feedUrl] の購読を登録する。
/// sqlite のときは DB の親ディレクトリを作り、マイグレーションを当てる。
Future<Repositories> openRepositories(
  RepositoryConfig config, {
  required String feedUrl,
}) async {
  switch (config.kind) {
    case RepositoryKind.memory:
      return Repositories(
        subscriptions: await createDefaultSubscriptionRepository(
          feedUrl: feedUrl,
        ),
        articles: InMemoryArticleRepository(),
        close: () {},
      );
    case RepositoryKind.sqlite:
      final file = File(config.databasePath);
      file.parent.createSync(recursive: true);
      final db = sqlite3.open(config.databasePath);
      migrateSqliteSchema(db);
      return Repositories(
        subscriptions: await createDefaultSubscriptionRepository(
          repository: SqliteSubscriptionRepository(db),
          feedUrl: feedUrl,
        ),
        articles: SqliteArticleRepository(db),
        close: db.close,
      );
  }
}
