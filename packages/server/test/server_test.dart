import 'package:server/server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void noopLogger(String message, bool isError) {}

void main() {
  group('buildHandler', () {
    final healthzRequest = Request(
      'GET',
      Uri.parse('http://localhost/healthz'),
    );

    test('should return 200 when GET /healthz is requested', () async {
      // Given: ログを抑止したハンドラ
      final handler = buildHandler(logger: noopLogger);

      // When: GET /healthz を処理する
      final response = await handler(healthzRequest);

      // Then: ステータスコードが 200 になる
      expect(response.statusCode, equals(200));
    });

    test('should return body ok when GET /healthz is requested', () async {
      // Given: ログを抑止したハンドラ
      final handler = buildHandler(logger: noopLogger);

      // When: GET /healthz を処理する
      final response = await handler(healthzRequest);

      // Then: ボディが ok になる
      expect(await response.readAsString(), equals('ok'));
    });

    test('should return 404 when an undefined path is requested', () async {
      // Given: ログを抑止したハンドラ
      final handler = buildHandler(logger: noopLogger);

      // When: 未定義パスを処理する
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/unknown')),
      );

      // Then: ステータスコードが 404 になる
      expect(response.statusCode, equals(404));
    });

    test('should log one non-error entry when a request is handled', () async {
      // Given: ログを記録するロガーを注入したハンドラ
      final logs = <(String, bool)>[];
      final handler = buildHandler(logger: (m, e) => logs.add((m, e)));

      // When: GET /healthz を処理する
      await handler(healthzRequest);

      // Then: エラーではないログが1件、メソッド・ステータス・パス付きで出力される
      expect(logs, hasLength(1));
      expect(logs.single.$2, isFalse);
      expect(logs.single.$1, contains('GET'));
      expect(logs.single.$1, contains('[200]'));
      expect(logs.single.$1, contains('/healthz'));
    });
  });

  group('smoke', () {
    test('should run the test infrastructure when dart test is executed', () {
      // Given: テスト基盤が導入されている
      const a = 1;
      const b = 1;

      // When: 加算を実行する
      final result = a + b;

      // Then: 期待どおりの結果になる
      expect(result, equals(2));
    });
  });
}
