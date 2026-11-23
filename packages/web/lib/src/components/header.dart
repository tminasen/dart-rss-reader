import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../realtime/connection_status.dart';
import '../theme.dart';

class Header extends StatelessComponent {
  const Header({this.connectionStatus, super.key});

  /// リアルタイム接続の状態。null の場合は状態を表示しない。
  final ConnectionStatus? connectionStatus;

  @override
  Component build(BuildContext context) {
    final status = connectionStatus;
    return header(
      styles: const Styles(
        display: Display.flex,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.spaceBetween,
        backgroundColor: bgWhite,
        border: Border.only(
          bottom: BorderSide.solid(color: borderBlack, width: Unit.pixels(1)),
        ),
        padding: Padding.symmetric(
          vertical: Unit.pixels(16),
          horizontal: Unit.pixels(32),
        ),
      ),
      [
        h1(
          styles: const Styles(
            margin: Margin.zero,
            fontSize: Unit.pixels(18),
            fontWeight: FontWeight.bold,
            color: textBlack,
          ),
          [Component.text('Dart RSS Reader')],
        ),
        if (status != null) _ConnectionIndicator(status: status),
      ],
    );
  }
}

class _ConnectionIndicator extends StatelessComponent {
  const _ConnectionIndicator({required this.status});

  final ConnectionStatus status;

  @override
  Component build(BuildContext context) {
    final isConnected = status == ConnectionStatus.connected;
    return div(
      styles: const Styles(
        display: Display.flex,
        alignItems: AlignItems.center,
        gap: Gap.all(Unit.pixels(8)),
      ),
      [
        div(
          styles: Styles(
            width: const Unit.pixels(8),
            height: const Unit.pixels(8),
            radius: const BorderRadius.circular(Unit.pixels(999)),
            backgroundColor: isConnected ? bgGreen : bgYellow,
          ),
          [],
        ),
        span(
          styles: const Styles(
            fontSize: Unit.pixels(12),
            fontWeight: FontWeight.w500,
            color: textBlack,
            lineHeight: lineHeightBase,
          ),
          [Component.text(isConnected ? 'リアルタイム接続中' : '再接続中…')],
        ),
      ],
    );
  }
}
