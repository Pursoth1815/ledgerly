import 'package:flutter/widgets.dart';

import '../loopd_colors.dart';
import '../loopd_motion.dart';

/// The animated on and off switch from the More mockup: a 52 × 32 track that
/// fades to [activeColor], and a white knob that slides with a spring.
class LoopdSwitch extends StatelessWidget {
  const LoopdSwitch({required this.value, required this.onChanged, required this.label, this.activeColor, super.key});

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Read by screen readers, such as "Dark theme".
  final String label;

  /// Each setting's own colour; green by default.
  final Color? activeColor;

  static const _width = 52.0;
  static const _height = 32.0;
  static const _knob = 26.0;
  static const _inset = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = LoopdMotion.of(context);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        // 44 px tall hit area around the 32 px track.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: motion.standard,
            curve: LoopdMotion.ease,
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              color: value ? (activeColor ?? colors.money) : colors.switchOff,
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            child: AnimatedAlign(
              duration: motion.emphasis,
              curve: LoopdMotion.spring,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(_inset),
                width: _knob,
                height: _knob,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
