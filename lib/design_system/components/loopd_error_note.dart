import 'package:flutter/material.dart';

import '../loopd_colors.dart';
import '../loopd_spacing.dart';
import '../loopd_typography.dart';

/// A problem with what was typed in a form, shown above its Save button, such
/// as "Primary already ends ••2210." (owner, 18 Nov 2026): a soft red box
/// with a red border, an error icon on the left and the message beside it.
/// Screen readers announce it as soon as it appears.
class LoopdErrorNote extends StatelessWidget {
  const LoopdErrorNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: c.dangerTint,
          borderRadius: BorderRadius.circular(LoopdRadius.tile),
          border: Border.all(color: c.danger.withValues(alpha: 0.55)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(Icons.error_outline_rounded, size: 18, color: c.danger)),
            const SizedBox(width: LoopdSpace.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  message,
                  style: LoopdType.caption.copyWith(color: c.danger, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
