import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/design_system/loopd_colors.dart';
import 'package:loopd/design_system/loopd_theme.dart';

/// WCAG relative luminance of an opaque colour.
double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final (x, y) = (_luminance(a), _luminance(b));
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  for (final (name, c) in [('dark', LoopdColors.dark), ('light', LoopdColors.light)]) {
    group('$name palette', () {
      // Proposal section 18: text contrast of at least 4.5 to 1.
      for (final (textName, text) in [
        ('primary', c.textPrimary),
        ('secondary', c.textSecondary),
        ('muted', c.textMuted),
      ]) {
        for (final (surfaceName, surface) in [
          ('background', c.background),
          ('surface', c.surface),
          ('raised surface', c.surfaceRaised),
        ]) {
          test('$textName text on the $surfaceName is readable (4.5:1)', () {
            expect(_contrast(text, surface), greaterThanOrEqualTo(4.5));
          });
        }
      }

      test('module accents are readable as text on the background (4.5:1)', () {
        for (final accent in [
          c.money,
          c.creditCard,
          c.cash,
          c.lending,
          c.travel,
          c.notes,
          c.vault,
          c.danger,
          c.review,
        ]) {
          expect(_contrast(accent, c.background), greaterThanOrEqualTo(4.5), reason: '$accent');
        }
      });

      test('the filled button label is readable', () {
        expect(_contrast(c.onButton, c.buttonFill), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('UPI, Credit Card and Cash are three different colours in both themes', () {
    for (final c in [LoopdColors.dark, LoopdColors.light]) {
      expect({c.money, c.creditCard, c.cash}, hasLength(3));
    }
  });

  test('the theme carries the palette, the Loopd font and no ripple', () {
    for (final brightness in Brightness.values) {
      final theme = loopdTheme(brightness);
      expect(theme.extension<LoopdColors>(), LoopdColors.forBrightness(brightness));
      expect(theme.textTheme.bodyLarge!.fontFamily, 'PlusJakartaSans');
      expect(theme.splashFactory, NoSplash.splashFactory);
      expect(theme.scaffoldBackgroundColor, LoopdColors.forBrightness(brightness).background);
    }
  });
}
