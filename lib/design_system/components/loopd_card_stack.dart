import 'package:flutter/widgets.dart';

import '../loopd_colors.dart';
import '../loopd_spacing.dart';
import 'loopd_pressable.dart';

/// The review stack on Today (review round 1, item 3): the top card, with
/// up to two card edges peeking out below it for the cards waiting behind.
/// Tapping the edges opens the full list.
class LoopdCardStack extends StatelessWidget {
  const LoopdCardStack({required this.top, required this.behind, this.onOpen, this.openLabel, super.key});

  /// The card on top, usually a [LoopdCard].
  final Widget top;

  /// How many cards wait behind it; up to two edges are drawn.
  final int behind;
  final VoidCallback? onOpen;

  /// Read by screen readers, such as "Open Review Inbox, 2 more waiting".
  final String? openLabel;

  /// How much of each waiting card shows below the one in front of it.
  static const peek = 10.0;

  /// How far the edges reach up behind the card in front.
  static const _hidden = 14.0;

  @override
  Widget build(BuildContext context) {
    if (behind <= 0) return top;
    final colors = context.colors;
    final count = behind.clamp(1, 2);
    Widget edge(int depth) {
      // depth 0 is right behind the top card; each one is narrower and fainter.
      final inset = 0.03 * (depth + 1);
      return Positioned(
        left: 0,
        right: 0,
        bottom: (count - depth - 1) * peek,
        height: (depth + 1) * peek + _hidden,
        child: FractionallySizedBox(
          widthFactor: 1 - 2 * inset,
          child: Opacity(
            opacity: depth == 0 ? 1 : 0.75,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border.all(color: colors.line),
              ),
            ),
          ),
        ),
      );
    }

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        for (var depth = count - 1; depth >= 0; depth--) edge(depth),
        Padding(
          padding: EdgeInsets.only(bottom: count * peek),
          child: top,
        ),
      ],
    );
    if (onOpen == null) return stack;
    // The edges are only 10 to 20 px tall. The press area reaches 44 px with
    // space added below them, and covers at most 12 px of the card's bottom
    // padding, which stays clear of the card's own buttons (18 px padding).
    final openSpace = LoopdSize.minTouch - count * peek - 12;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: openSpace),
          child: stack,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: LoopdSize.minTouch,
          child: LoopdPressable(onTap: onOpen, label: openLabel, child: const SizedBox.expand()),
        ),
      ],
    );
  }
}
