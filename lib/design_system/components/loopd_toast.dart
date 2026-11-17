import 'package:flutter/material.dart';

import '../loopd_colors.dart';
import '../loopd_typography.dart';

/// A short message at the bottom of the screen, such as "Built in Phase 3".
void showLoopdToast(BuildContext context, String message) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: LoopdType.label.copyWith(color: colors.onButton)),
        backgroundColor: colors.buttonFill,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: const StadiumBorder(),
      ),
    );
}
