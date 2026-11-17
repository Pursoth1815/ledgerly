import 'package:flutter/material.dart';
import 'package:loopd/design_system/loopd_theme.dart';

/// Wraps [child] in a Loopd-themed app for widget tests.
Widget loopdTestApp(Widget child, {Brightness brightness = Brightness.dark, bool reduceMotion = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: loopdTheme(brightness),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);
