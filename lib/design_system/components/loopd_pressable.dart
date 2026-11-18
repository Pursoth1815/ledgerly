import 'package:flutter/widgets.dart';

import '../loopd_motion.dart';

/// Loopd's press state instead of a Material ripple (proposal section 18):
/// the child shrinks slightly while pressed and springs back.
///
/// Gives the child at least [minSize] of tappable area, and exposes [label]
/// as a button to screen readers.
class LoopdPressable extends StatefulWidget {
  const LoopdPressable({
    required this.child,
    required this.onTap,
    this.label,
    this.selected,
    this.pressedScale = 0.97,
    this.onLongPress,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Such as starting to choose categories to delete.
  final VoidCallback? onLongPress;
  final String? label;

  /// For choices such as chips: reported to screen readers when not null.
  final bool? selected;
  final double pressedScale;

  @override
  State<LoopdPressable> createState() => _LoopdPressableState();
}

class _LoopdPressableState extends State<LoopdPressable> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed && widget.onTap != null) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final motion = LoopdMotion.of(context);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.label,
      selected: widget.selected,
      // With a label, the child's own text is not read a second time, so the
      // tap is offered here.
      excludeSemantics: widget.label != null,
      onTap: widget.label != null ? widget.onTap : null,
      onLongPress: widget.label != null ? widget.onLongPress : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        // No handlers at all when disabled, so screen readers do not offer a tap.
        onTapDown: widget.onTap == null ? null : (_) => _set(true),
        onTapUp: widget.onTap == null ? null : (_) => _set(false),
        onTapCancel: widget.onTap == null ? null : () => _set(false),
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: motion.quick,
          curve: _pressed ? LoopdMotion.ease : LoopdMotion.spring,
          child: widget.child,
        ),
      ),
    );
  }
}
