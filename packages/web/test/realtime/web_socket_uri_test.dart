import 'package:test/test.dart';
import 'package:web_app/src/realtime/web_socket_uri.dart';

void main() {
  group('webSocketUriFrom', () {
    test('should return ws URL with /ws path when base URL is http', () {
      // Given: http のベース URL
      final base = Uri.parse('http://localhost:8080');

      // When: webSocketUriFrom を呼ぶ
      final uri = webSocketUriFrom(base);

      // Then: ws スキームで /ws パスの URL が返る
      expect(uri, equals(Uri.parse('ws://localhost:8080/ws')));
    });

    test('should return wss URL with /ws path when base URL is https', () {
      // Given: https のベース URL
      final base = Uri.parse('https://api.example.com');

      // When: webSocketUriFrom を呼ぶ
      final uri = webSocketUriFrom(base);

      // Then: wss スキームで /ws パスの URL が返る
      expect(uri, equals(Uri.parse('wss://api.example.com/ws')));
    });

    test('should return /ws path when base URL has trailing slash', () {
      // Given: 末尾スラッシュ付きのベース URL
      final base = Uri.parse('http://localhost:8080/');

      // When: webSocketUriFrom を呼ぶ
      final uri = webSocketUriFrom(base);

      // Then: パスは /ws になる
      expect(uri, equals(Uri.parse('ws://localhost:8080/ws')));
    });
  });
}
