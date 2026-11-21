import 'package:jaspr/dom.dart';

// tminasen Colors（Figma の変数名）
const textBlack = Color('#333333');
const textSubGray = Color('#4B5563');
const bgWhite = Color('#FFFFFF');
const bgLightGray = Color('#F5F5F5');
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
