import 'package:jaspr_test/jaspr_test.dart';
import 'package:web_app/src/components/header.dart';

void main() {
  group('Header', () {
    testComponents('should render app name when built', (tester) async {
      // Given: なし

      // When: Header を描画する
      tester.pumpComponent(const Header());

      // Then: アプリ名が描画される
      expect(find.text('Dart RSS Reader'), findsOneComponent);
    });
  });
}
