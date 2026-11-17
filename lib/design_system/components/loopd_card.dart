import 'package:flutter/widgets.dart';

import '../loopd_colors.dart';
import '../loopd_spacing.dart';
import 'loopd_pressable.dart';

/// A rounded surface with a hairline border: depth through tonal layers, not
/// shadows (proposal section 18). Pressable when [onTap] is given.
class LoopdCard extends StatelessWidget {
  const LoopdCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = LoopdRadius.section,
    this.color,
    this.bordered = true,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Defaults to the surface colour; a module tint for coloured cards.
  final Color? color;

  /// Tinted cards have no border in the mockups.
  final bool bordered;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: colors.line) : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) {
      return semanticLabel == null ? card : Semantics(container: true, label: semanticLabel, child: card);
    }
    return LoopdPressable(onTap: onTap, label: semanticLabel, pressedScale: 0.98, child: card);
  }
}
