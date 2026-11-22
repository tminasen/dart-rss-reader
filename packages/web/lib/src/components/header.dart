import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../theme.dart';

class Header extends StatelessComponent {
  const Header({super.key});

  @override
  Component build(BuildContext context) {
    return header(
      styles: const Styles(
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
      ],
    );
  }
}
