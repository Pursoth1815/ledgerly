import 'package:flutter/widgets.dart';

import '../loopd_colors.dart';
import '../loopd_spacing.dart';
import '../loopd_typography.dart';

/// The payment-source strip from the Today and Review mockups: a mini card in
/// the bank's colour, the account name, how it was paid, and a method badge
/// on the right (review round 1, item 5).
class LoopdSourceStrip extends StatelessWidget {
  const LoopdSourceStrip({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  /// Usually a [LoopdMiniCard].
  final Widget leading;
  final String title;
  final String subtitle;

  /// Usually a badge naming the method: UPI, CC or Cash.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surfaceRaised, borderRadius: BorderRadius.circular(LoopdRadius.inner)),
      child: Padding(
        padding: const EdgeInsets.all(LoopdSpace.md),
        child: Row(
          children: [
            leading,
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LoopdType.label.copyWith(color: colors.textPrimary),
                  ),
                  const SizedBox(height: LoopdSpace.xxs),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LoopdType.caption.copyWith(color: colors.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: LoopdSpace.md), trailing!],
          ],
        ),
      ),
    );
  }
}

/// A 46 × 30 card in the bank's [color], with a chip and the last four
/// digits (always made-up or the owner's own, never shown elsewhere).
class LoopdMiniCard extends StatelessWidget {
  const LoopdMiniCard({required this.color, this.lastFour, super.key});

  final Color color;
  final String? lastFour;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 46,
      height: 30,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 7,
            child: Container(
              width: 10,
              height: 8,
              decoration: BoxDecoration(color: const Color(0xFFFCD34D), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          if (lastFour != null)
            Positioned(
              right: 5,
              bottom: 3,
              child: Text(
                lastFour!,
                style: const TextStyle(
                  fontFamily: LoopdType.mono,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFFFFF),
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
