enum RepositoryKind { memory, sqlite }

const defaultDatabasePath = 'data/rss_reader.db';

/// どのリポジトリ実装を、どの DB ファイルで使うか。
final class RepositoryConfig {
  const RepositoryConfig({required this.kind, required this.databasePath});

  /// 環境変数 `REPOSITORY`（`memory` / `sqlite`、未指定なら `sqlite`）と
  /// `DATABASE_PATH`（未指定なら [defaultDatabasePath]）から作る。
  /// 空文字は未指定として扱う。`REPOSITORY` が不正なら [ArgumentError] を投げる。
  factory RepositoryConfig.fromEnvironment(Map<String, String> environment) {
    final repository = _nonEmpty(environment['REPOSITORY']);
    return RepositoryConfig(
      kind: switch (repository) {
        null || 'sqlite' => RepositoryKind.sqlite,
        'memory' => RepositoryKind.memory,
        _ => throw ArgumentError.value(
          repository,
          'REPOSITORY',
          'must be "memory" or "sqlite"',
        ),
      },
      databasePath:
          _nonEmpty(environment['DATABASE_PATH']) ?? defaultDatabasePath,
    );
  }

  final RepositoryKind kind;
  final String databasePath;

  @override
  bool operator ==(Object other) =>
      other is RepositoryConfig &&
      other.kind == kind &&
      other.databasePath == databasePath;

  @override
  int get hashCode => Object.hash(kind, databasePath);
}

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;
