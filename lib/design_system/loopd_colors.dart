import 'package:flutter/widgets.dart';

/// The neutral colours from the approved mockups (`docs/mockups/`), in dark
/// (designed first) and light. Only the tokens in use so far; the module
/// accents and the rest of the design system arrive in Phase 1.
@immutable
class LoopdColors {
  const LoopdColors._({
    required this.background,
    required this.surface,
    required this.line,
    required this.textPrimary,
    required this.textMuted,
  });

  /// Mockup tokens: bg, s1, line, t1, t3.
  static const dark = LoopdColors._(
    background: Color(0xFF0D0F14),
    surface: Color(0xFF161922),
    line: Color(0xFF2B3040),
    textPrimary: Color(0xFFF3F5F9),
    textMuted: Color(0xFF8F96A6),
  );

  static const light = LoopdColors._(
    background: Color(0xFFF3F4F8),
    surface: Color(0xFFFFFFFF),
    line: Color(0xFFDDE1E9),
    textPrimary: Color(0xFF11141B),
    textMuted: Color(0xFF5D6474),
  );

  static LoopdColors forBrightness(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  final Color background;
  final Color surface;
  final Color line;
  final Color textPrimary;
  final Color textMuted;
}
