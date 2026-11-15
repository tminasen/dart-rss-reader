import 'package:test/test.dart';

void main() {
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
