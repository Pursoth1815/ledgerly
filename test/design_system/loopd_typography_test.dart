import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/design_system/loopd_typography.dart';

/// The sizes the approved mockups use (docs/mockups).
void main() {
  test('tab page titles are 34 px ExtraBold on a 44 px line', () {
    expect(LoopdType.display.fontSize, 34);
    expect(LoopdType.display.fontWeight, FontWeight.w800);
    expect(LoopdType.display.fontSize! * LoopdType.display.height!, closeTo(44, 0.01));
  });

  test('inner page titles are 30 px and big amounts 36 px', () {
    expect(LoopdType.pageTitle.fontSize, 30);
    expect(LoopdType.amountLarge.fontSize, 36);
  });

  test('amounts use tabular figures so columns line up', () {
    for (final style in [LoopdType.amount, LoopdType.amountLarge]) {
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });

  test('PNRs and the command line use JetBrains Mono, everything else Plus Jakarta Sans', () {
    expect(LoopdType.code.fontFamily, LoopdType.mono);
    for (final style in [LoopdType.display, LoopdType.pageTitle, LoopdType.title, LoopdType.body, LoopdType.micro]) {
      expect(style.fontFamily, LoopdType.sans);
    }
  });
}
