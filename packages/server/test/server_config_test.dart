import 'dart:math';

import 'package:server/src/server_config.dart';
import 'package:test/test.dart';

const defaultServerConfig = ServerConfig(
  host: '127.0.0.1',
  port: 8080,
  allowedOrigins: {'http://localhost:8081'},
);

void main() {
  group('ServerConfig.fromEnvironment', () {
    // T1
    test('should use defaults when nothing is set', () {
      // Given: 何も指定していない環境変数
      final environment = <String, String>{};

      // When: 設定を作る
      final config = ServerConfig.fromEnvironment(environment);

      // Then: 既定値と等しい
      expect(config, equals(defaultServerConfig));
    });

    // T2
    test('should treat empty values as unset when they are empty strings', () {
      // Given: 空文字の環境変数
      final environment = {'HOST': '', 'PORT': '', 'ALLOWED_ORIGINS': ''};

      // When: 設定を作る
      final config = ServerConfig.fromEnvironment(environment);

      // Then: 既定値と等しい
      expect(config, equals(defaultServerConfig));
    });

    // T3
    test('should use the given host when HOST is set', () {
      // Given: HOST を指定した環境変数
      final environment = {'HOST': '0.0.0.0'};

      // When: 設定を作る
      final config = ServerConfig.fromEnvironment(environment);

      // Then: 指定したホストが採用され、他は既定値になる
      expect(config.host, equals('0.0.0.0'));
      expect(config.port, equals(8080));
      expect(config.allowedOrigins, equals({'http://localhost:8081'}));
    });

    // T4
    test('should use the given port when PORT is set', () {
      // Given: PORT を指定した環境変数
      final environment = {'PORT': '9000'};

      // When: 設定を作る
      final config = ServerConfig.fromEnvironment(environment);

      // Then: 指定したポートが採用される
      expect(config.port, equals(9000));
    });

    // T5
    test(
      'should parse a single origin into a single-element set when ALLOWED_ORIGINS has one origin',
      () {
        // Given: 単一オリジンの ALLOWED_ORIGINS
        final environment = {'ALLOWED_ORIGINS': 'https://rss.example.com'};

        // When: 設定を作る
        final config = ServerConfig.fromEnvironment(environment);

        // Then: 1要素の集合になる
        expect(config.allowedOrigins, equals({'https://rss.example.com'}));
      },
    );

    // T6
    test(
      'should trim and drop empty items when ALLOWED_ORIGINS has commas and spaces',
      () {
        // Given: カンマ区切り・空白・末尾カンマを含む ALLOWED_ORIGINS
        final environment = {
          'ALLOWED_ORIGINS': 'http://localhost:8081, http://127.0.0.1:8081, ',
        };

        // When: 設定を作る
        final config = ServerConfig.fromEnvironment(environment);

        // Then: トリム・空要素除外された集合になる
        expect(
          config.allowedOrigins,
          equals({'http://localhost:8081', 'http://127.0.0.1:8081'}),
        );
      },
    );

    // T7
    test('should throw ArgumentError when HOST is whitespace only', () {
      // Given: 空白のみの HOST
      final environment = {'HOST': '   '};

      // When / Then: 拒否される
      expect(
        () => ServerConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    // T8
    test('should throw ArgumentError when HOST contains whitespace', () {
      // Given: 空白文字を含む HOST
      final environment = {'HOST': '0.0.0.0 8080'};

      // When / Then: 拒否される
      expect(
        () => ServerConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    // T9
    test('should throw ArgumentError when PORT is not an integer', () {
      // Given: 整数でない PORT
      final environment = {'PORT': 'abc'};

      // When / Then: 拒否される
      expect(
        () => ServerConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    // T10
    test(
      'should throw ArgumentError when ALLOWED_ORIGINS contains non-http scheme',
      () {
        // Given: http/https 以外のスキームを含む ALLOWED_ORIGINS
        final environment = {'ALLOWED_ORIGINS': 'ftp://localhost:8081'};

        // When / Then: 拒否される
        expect(
          () => ServerConfig.fromEnvironment(environment),
          throwsArgumentError,
        );
      },
    );

    // T11
    test(
      'should throw ArgumentError when ALLOWED_ORIGINS contains origin without host',
      () {
        // Given: ホストがないオリジンを含む ALLOWED_ORIGINS
        final environment = {'ALLOWED_ORIGINS': 'http://'};

        // When / Then: 拒否される
        expect(
          () => ServerConfig.fromEnvironment(environment),
          throwsArgumentError,
        );
      },
    );

    // T12
    test(
      'should throw ArgumentError when ALLOWED_ORIGINS contains origin with path',
      () {
        // Given: 末尾スラッシュ（パス）を含むオリジン
        final environment = {'ALLOWED_ORIGINS': 'http://localhost:8081/'};

        // When / Then: 拒否される
        expect(
          () => ServerConfig.fromEnvironment(environment),
          throwsArgumentError,
        );
      },
    );

    // T13
    test(
      'should throw ArgumentError when ALLOWED_ORIGINS contains origin with query',
      () {
        // Given: クエリを含むオリジン
        final environment = {'ALLOWED_ORIGINS': 'http://localhost:8081?a=1'};

        // When / Then: 拒否される
        expect(
          () => ServerConfig.fromEnvironment(environment),
          throwsArgumentError,
        );
      },
    );

    // T14
    test(
      'should throw ArgumentError when ALLOWED_ORIGINS has no valid origins after trimming',
      () {
        // Given: カンマと空白のみで有効オリジンが0件の ALLOWED_ORIGINS
        final environment = {'ALLOWED_ORIGINS': ', , '};

        // When / Then: 拒否される
        expect(
          () => ServerConfig.fromEnvironment(environment),
          throwsArgumentError,
        );
      },
    );

    // T15
    test('should throw ArgumentError when PORT is 0', () {
      // Given: 下限未満の PORT
      final environment = {'PORT': '0'};

      // When / Then: 拒否される
      expect(
        () => ServerConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });

    // T16
    test('should accept 1 when PORT is 1', () {
      // Given: 下限ちょうどの PORT
      final environment = {'PORT': '1'};

      // When: 設定を作る
      final config = ServerConfig.fromEnvironment(environment);

      // Then: 1 が採用される
      expect(config.port, equals(1));
    });

    // T17
    test('should accept 65535 when PORT is 65535', () {
      // Given: 上限ちょうどの PORT
      final environment = {'PORT': '65535'};

      // When: 設定を作る
      final config = ServerConfig.fromEnvironment(environment);

      // Then: 65535 が採用される
      expect(config.port, equals(65535));
    });

    // T18
    test('should throw ArgumentError when PORT is 65536', () {
      // Given: 上限超過の PORT
      final environment = {'PORT': '65536'};

      // When / Then: 拒否される
      expect(
        () => ServerConfig.fromEnvironment(environment),
        throwsArgumentError,
      );
    });
  });

  group('P1: ServerConfig invariants', () {
    final random = Random(42);
    final hostSamples = ['127.0.0.1', '0.0.0.0', 'localhost', '::'];
    final originHosts = ['localhost', '127.0.0.1', '[::1]', 'rss.example.com'];

    for (var i = 0; i < 100; i++) {
      final host = random.nextBool()
          ? hostSamples[random.nextInt(hostSamples.length)]
          : 'host-${random.nextInt(1000)}.local';
      final port = (1 + random.nextInt(65535)).toString();
      final originCount = 1 + random.nextInt(5);
      final rawOrigins = [
        for (var j = 0; j < originCount; j++)
          '${random.nextBool() ? 'http' : 'https'}://'
              '${originHosts[random.nextInt(originHosts.length)]}'
              '${random.nextBool() ? ':${1 + random.nextInt(65535)}' : ''}',
      ];
      String formatOrigins(List<String> list) => [
        for (final origin in list)
          '${' ' * random.nextInt(3)}$origin${' ' * random.nextInt(3)}',
      ].join(',');

      final forwardOrigins = formatOrigins(rawOrigins);
      final reversedOrigins = formatOrigins(rawOrigins.reversed.toList());

      test('should satisfy invariants for generated case $i', () {
        // Given: 有効入力ドメインから生成した環境変数と、オリジン逆順の環境変数
        final envForward = {
          'HOST': host,
          'PORT': port,
          'ALLOWED_ORIGINS': forwardOrigins,
        };
        final envReversed = {
          'HOST': host,
          'PORT': port,
          'ALLOWED_ORIGINS': reversedOrigins,
        };

        // When: 設定を作る
        final config = ServerConfig.fromEnvironment(envForward);
        final reversedConfig = ServerConfig.fromEnvironment(envReversed);

        // Then: ポート範囲・非空ホスト・正規化済みオリジン集合・順序不変性を満たす
        expect(config.port, inInclusiveRange(1, 65535));
        expect(config.host, isNotEmpty);
        expect(config.allowedOrigins, isNotEmpty);
        expect(
          config.allowedOrigins.every(
            (o) =>
                o == o.trim() &&
                (o.startsWith('http://') || o.startsWith('https://')),
          ),
          isTrue,
        );
        expect(config.allowedOrigins, equals(reversedConfig.allowedOrigins));
      });
    }
  });
}
