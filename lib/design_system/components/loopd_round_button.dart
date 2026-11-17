import 'package:flutter/widgets.dart';

import '../loopd_spacing.dart';
import 'loopd_pressable.dart';

/// A round icon button, such as the hourglass and theme buttons on Today's
/// header or the close button on a sheet (mockups: 44 or 40 px).
class LoopdRoundButton extends StatelessWidget {
  const LoopdRoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.size = LoopdSize.minTouch,
    this.iconSize = 20,
    super.key,
  });

  final IconData icon;

  /// Read by screen readers.
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => LoopdPressable(
    onTap: onTap,
    label: label,
    pressedScale: 0.92,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: iconSize, color: foreground),
    ),
  );
}
