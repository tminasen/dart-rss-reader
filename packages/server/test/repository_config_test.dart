import 'package:server/src/repository_config.dart';
import 'package:test/test.dart';

void main() {
  group('RepositoryConfig.fromEnvironment', () {
    test('should default to sqlite and default path when nothing is set', () {
      // Given: 何も指定していない環境変数
      final environment = <String, String>{};

      // When: 設定を作る
      final config = RepositoryConfig.fromEnvironment(environment);

      // Then: sqlite と既定のパスになる
      expect(
        config,
        const RepositoryConfig(
          kind: RepositoryKind.sqlite,
          databasePath: 'data/rss_reader.db',
        ),
      );
    });

    test('should use memory when REPOSITORY is memory', () {
      // Given: REPOSITORY=memory
      final environment = {'REPOSITORY': 'memory'};

      // When: 設定を作る
      final config = RepositoryConfig.fromEnvironment(environment);

      // Then: インメモリ版になる
      expect(config.kind, RepositoryKind.memory);
    });

    test('should use given path when REPOSITORY is sqlite with path', () {
      // Given: REPOSITORY=sqlite と DATABASE_PATH
      final environment = {
        'REPOSITORY': 'sqlite',
        'DATABASE_PATH': 'tmp/custom.db',
      };

      // When: 設定を作る
      final config = RepositoryConfig.fromEnvironment(environment);

      // Then: 指定したパスの sqlite になる
      expect(
        config,
        const RepositoryConfig(
          kind: RepositoryKind.sqlite,
          databasePath: 'tmp/custom.db',
        ),
      );
    });

    test('should throw ArgumentError when REPOSITORY is invalid', () {
      // Given: 不正な REPOSITORY
      final environment = {'REPOSITORY': 'postgres'};

      // When / Then: ArgumentError
      expect(
        () => RepositoryConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    test('should treat empty values as unset', () {
      // Given: 空文字の環境変数
      final environment = {'REPOSITORY': '', 'DATABASE_PATH': ''};

      // When: 設定を作る
      final config = RepositoryConfig.fromEnvironment(environment);

      // Then: 未指定と同じ（sqlite と既定のパス）
      expect(
        config,
        const RepositoryConfig(
          kind: RepositoryKind.sqlite,
          databasePath: 'data/rss_reader.db',
        ),
      );
    });
  });
}
