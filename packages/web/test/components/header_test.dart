import 'package:jaspr_test/jaspr_test.dart';
import 'package:web_app/src/components/header.dart';
import 'package:web_app/src/realtime/connection_status.dart';

void main() {
  group('Header', () {
    testComponents('should render app name when built', (tester) async {
      // Given: なし

      // When: Header を描画する
      tester.pumpComponent(const Header());

      // Then: アプリ名が描画される
      expect(find.text('Dart RSS Reader'), findsOneComponent);
    });

    testComponents(
      'should render reconnecting label when status is reconnecting',
      (tester) async {
        // Given: 未接続の状態

        // When: Header を描画する
        tester.pumpComponent(
          const Header(connectionStatus: ConnectionStatus.reconnecting),
        );

        // Then: 「再接続中…」だけが描画される
        expect(find.text('再接続中…'), findsOneComponent);
        expect(find.text('リアルタイム接続中'), findsNothing);
      },
    );

    testComponents('should render connected label when status is connected', (
      tester,
    ) async {
      // Given: 接続済みの状態

      // When: Header を描画する
      tester.pumpComponent(
        const Header(connectionStatus: ConnectionStatus.connected),
      );

      // Then: 「リアルタイム接続中」だけが描画される
      expect(find.text('リアルタイム接続中'), findsOneComponent);
      expect(find.text('再接続中…'), findsNothing);
    });

    testComponents('should render no status label when status is omitted', (
      tester,
    ) async {
      // Given: 接続状態を渡さない

      // When: Header を描画する
      tester.pumpComponent(const Header());

      // Then: 状態の表示はなく、アプリ名だけが描画される
      expect(find.text('リアルタイム接続中'), findsNothing);
      expect(find.text('再接続中…'), findsNothing);
      expect(find.text('Dart RSS Reader'), findsOneComponent);
    });
  });
}
