import 'package:flutter/widgets.dart';

import '../loopd_colors.dart';
import '../loopd_spacing.dart';
import '../loopd_typography.dart';
import 'loopd_pressable.dart';

enum LoopdButtonStyle {
  /// Filled with an accent, such as green Looks Good or Save.
  accent,

  /// Filled with the strongest neutral.
  solid,

  /// A hairline outline, such as Review.
  outlined,

  /// A red outline, such as Delete at the end of an edit form.
  danger,
}

/// A 48 px pill button (mockups: Review and Looks Good).
class LoopdButton extends StatelessWidget {
  const LoopdButton({
    required this.label,
    required this.onTap,
    this.style = LoopdButtonStyle.accent,
    this.accent,
    this.icon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final LoopdButtonStyle style;

  /// The fill for [LoopdButtonStyle.accent]; green (Save, Looks Good) by default.
  final Color? accent;

  /// Shown before the label, such as a cloud on "Back up now".
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    // The button's own colours when enabled.
    final (ownFill, ownForeground, ownBorder) = switch (style) {
      LoopdButtonStyle.accent => (accent ?? colors.money, colors.onAccent, null as Color?),
      LoopdButtonStyle.solid => (colors.buttonFill, colors.onButton, null as Color?),
      LoopdButtonStyle.outlined => (null as Color?, colors.textPrimary, colors.line),
      LoopdButtonStyle.danger => (null as Color?, colors.danger, colors.danger),
    };
    // A disabled button keeps its own colours, faded (owner's choice, 17 Nov 2026).
    final (fill, foreground, borderColor) = (ownFill, ownForeground, ownBorder);
    final opacity = enabled ? 1.0 : 0.4;
    final border = borderColor == null ? null : Border.all(color: borderColor, width: 1.5);
    return LoopdPressable(
      onTap: onTap,
      label: label,
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: LoopdSize.button,
          padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.xl),
          decoration: BoxDecoration(
            color: fill,
            border: border,
            borderRadius: BorderRadius.circular(LoopdSize.button / 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: foreground), const SizedBox(width: LoopdSpace.sm)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LoopdType.label.copyWith(color: foreground),
                ),
              ),
              if (trailingIcon != null) ...[const SizedBox(width: 6), Icon(trailingIcon, size: 18, color: foreground)],
            ],
          ),
        ),
      ),
    );
  }
}
