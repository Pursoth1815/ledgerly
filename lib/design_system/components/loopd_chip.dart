import 'package:flutter/widgets.dart';

import '../loopd_colors.dart';
import '../loopd_motion.dart';
import '../loopd_spacing.dart';
import '../loopd_typography.dart';
import 'loopd_pressable.dart';

/// A small pill with an accent label on its tint, such as "5 New", "CC" or
/// "UPI" (mockups: 12 px ExtraBold).
class LoopdBadge extends StatelessWidget {
  const LoopdBadge({required this.label, required this.color, required this.tint, super.key});

  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(LoopdRadius.pill)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: LoopdSpace.xs),
      child: Text(
        label,
        style: LoopdType.caption.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

/// A choice chip, such as a category: a coloured dot and a label on a raised
/// surface. When [selected], it takes the [dotColor]'s ring.
class LoopdChip extends StatelessWidget {
  const LoopdChip({required this.label, this.dotColor, this.icon, this.selected = false, this.onTap, super.key});

  final String label;
  final Color? dotColor;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = LoopdMotion.of(context);
    final accent = dotColor ?? colors.textPrimary;
    final chip = AnimatedContainer(
      duration: motion.standard,
      curve: LoopdMotion.ease,
      height: LoopdSize.chip,
      padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.md),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(LoopdSize.chip / 2),
        border: Border.all(color: selected ? accent : colors.surfaceRaised, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: accent)
          else if (dotColor != null)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          if (icon != null || dotColor != null) const SizedBox(width: 6),
          Text(label, style: LoopdType.small.copyWith(color: colors.textPrimary)),
        ],
      ),
    );
    if (onTap == null) return chip;
    // The chip is 30 px tall; the press area grows to the 44 px minimum.
    return LoopdPressable(
      onTap: onTap,
      label: label,
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LoopdSize.minTouch),
        child: Align(widthFactor: 1, heightFactor: 1, child: chip),
      ),
    );
  }
}
