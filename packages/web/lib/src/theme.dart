import 'package:jaspr/dom.dart';

// tminasen Colors（Figma の変数名）
const textBlack = Color('#333333');
const textSubGray = Color('#4B5563');
const textWhite = Color('#FFFFFF');
const bgWhite = Color('#FFFFFF');
const bgLightGray = Color('#F5F5F5');
const bgBlack = Color('#333333');
const bgGray = Color('#EBECF0');
const bgBlue = Color('#448AFF');
const bgRed = Color('#EB5757');
const bgGreen = Color('#27AE60');
const bgYellow = Color('#F2C94C');
const bgLightYellow = Color('#F5D67A');
const borderBlack = Color('#333333');

const notoSansJp = FontFamily.list([
  FontFamily('Noto Sans JP'),
  FontFamilies.sansSerif,
]);

// 単位なしの line-height 1.5（Figma）
const lineHeightBase = Unit.expression('1.5');

// アプリ全体に効くスタイル。@css により jaspr のビルドで main.css に出力される。
@css
List<StyleRule> get globalStyles => [
  css('html, body').styles(
    margin: Margin.zero,
    padding: Padding.zero,
    fontFamily: notoSansJp,
    color: textBlack,
    lineHeight: lineHeightBase,
  ),
];
