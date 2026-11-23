import 'dart:io';

import 'package:server/src/repositories.dart';
import 'package:server/src/repository/in_memory_article_repository.dart';
import 'package:server/src/repository/in_memory_subscription_repository.dart';
import 'package:server/src/repository/sqlite_article_repository.dart';
import 'package:server/src/repository/sqlite_subscription_repository.dart';
import 'package:server/src/repository/subscription.dart';
import 'package:server/src/repository_config.dart';
import 'package:test/test.dart';

import 'repository/fixtures.dart';
import 'repository/sqlite_fixtures.dart';

void main() {
  group('openRepositories', () {
    test('should open in-memory repositories with default subscription '
        'when kind is memory', () async {
      // Given: memory の設定（DB パスは一時ディレクトリ）
      final path = tempDbPath();
      final config = RepositoryConfig(
        kind: RepositoryKind.memory,
        databasePath: path,
      );

      // When: 組み立てる
      final repositories = await openRepositories(config, feedUrl: feedUrlA);
      addTearDown(repositories.close);
      final all = await repositories.subscriptions.findAll();

      // Then: インメモリ版で、既定の購読が未取得の1件だけあり、DB ファイルはできない
      expect(repositories.subscriptions, isA<InMemorySubscriptionRepository>());
      expect(repositories.articles, isA<InMemoryArticleRepository>());
      expect(
        [for (final s in all) (s.feedUrl, s.feed, s.lastFetchedAt)],
        [(feedUrlA, null, null)],
      );
      expect(File(path).existsSync(), isFalse);
    });

    test('should create parent directory and open sqlite repositories '
        'when kind is sqlite', () async {
      // Given: まだ存在しない親ディレクトリの下の DB パス
      final path = tempDbPath().replaceFirst('rss.db', 'nested/dir/rss.db');
      final config = RepositoryConfig(
        kind: RepositoryKind.sqlite,
        databasePath: path,
      );

      // When: 組み立てる
      final repositories = await openRepositories(config, feedUrl: feedUrlA);
      final all = await repositories.subscriptions.findAll();
      repositories.close();

      // Then: ファイルができ、SQLite 版で、既定の購読が未取得の1件だけある
      expect(File(path).existsSync(), isTrue);
      expect(repositories.subscriptions, isA<SqliteSubscriptionRepository>());
      expect(repositories.articles, isA<SqliteArticleRepository>());
      expect(
        [for (final s in all) (s.feedUrl, s.feed, s.lastFetchedAt)],
        [(feedUrlA, null, null)],
      );
    });

    test('should keep data and not duplicate default subscription '
        'when reopened', () async {
      // Given: 購読と記事を書いて閉じた sqlite の設定
      final config = RepositoryConfig(
        kind: RepositoryKind.sqlite,
        databasePath: tempDbPath(),
      );
      final first = await openRepositories(config, feedUrl: feedUrlA);
      final s = (await first.subscriptions.findAll()).single;
      await first.subscriptions.updateFetched(
        s.id,
        feed: rssFeed,
        fetchedAt: fetchedAt1,
      );
      await first.articles.addAll(s.id, [rss(1)]);
      first.close();

      // When: 同じ設定でもう一度組み立てる（再起動）
      final second = await openRepositories(config, feedUrl: feedUrlA);
      addTearDown(second.close);
      final subscriptions = await second.subscriptions.findAll();
      final articles = await second.articles.find();

      // Then: 購読は重複せず、取得結果も記事も残っている
      expect(subscriptions, [
        Subscription(
          id: s.id,
          feedUrl: feedUrlA,
          feed: rssFeed,
          lastFetchedAt: fetchedAt1,
        ),
      ]);
      expect(articles, hasLength(1));
      expect(articles.single.article, rss(1));
      expect(articles.single.feedId, s.id);
    });

    test('should add the new URL and keep the old one '
        'when reopened with a different feed URL', () async {
      // Given: feedUrlA で開いて閉じた sqlite の設定
      final config = RepositoryConfig(
        kind: RepositoryKind.sqlite,
        databasePath: tempDbPath(),
      );
      final first = await openRepositories(config, feedUrl: feedUrlA);
      first.close();

      // When: feedUrlB でもう一度組み立てる
      final second = await openRepositories(config, feedUrl: feedUrlB);
      addTearDown(second.close);
      final subscriptions = await second.subscriptions.findAll();

      // Then: 旧URLが残り、新URLが登録順で追加されている
      expect([for (final s in subscriptions) s.feedUrl], [feedUrlA, feedUrlB]);
    });
  });
}
