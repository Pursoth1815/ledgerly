import 'package:flutter/material.dart';

import 'loopd_colors.dart';
import 'loopd_spacing.dart';
import 'loopd_typography.dart';

/// Builds the Material theme from Loopd's tokens, for dark or light.
///
/// Loopd draws most of its own components, so Material is configured only so
/// that stock widgets (text fields, dialogs, scrollbars) match: the Loopd
/// fonts and colours, and no ripple (proposal section 18: a custom press
/// state instead of the Material ripple).
ThemeData loopdTheme(Brightness brightness) {
  final c = LoopdColors.forBrightness(brightness);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.money,
    onPrimary: c.onAccent,
    secondary: c.creditCard,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: c.onAccent,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    outline: c.line,
    outlineVariant: c.line,
    surfaceContainerHighest: c.surfaceRaised,
  );
  TextStyle on(TextStyle style, Color color) => style.copyWith(color: color);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: LoopdType.sans,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    dividerColor: c.line,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: c.pressOverlay,
    hoverColor: Colors.transparent,
    textTheme: TextTheme(
      displayLarge: on(LoopdType.display, c.textPrimary),
      headlineMedium: on(LoopdType.pageTitle, c.textPrimary),
      titleLarge: on(LoopdType.title, c.textPrimary),
      titleMedium: on(LoopdType.heading, c.textPrimary),
      bodyLarge: on(LoopdType.body, c.textPrimary),
      bodyMedium: on(LoopdType.small, c.textPrimary),
      bodySmall: on(LoopdType.caption, c.textSecondary),
      labelLarge: on(LoopdType.label, c.textPrimary),
      labelSmall: on(LoopdType.micro, c.textMuted),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.money, selectionHandleColor: c.money),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBarrierColor: c.scrim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(LoopdRadius.sheet))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LoopdRadius.card)),
    ),
    extensions: [c],
  );
}
