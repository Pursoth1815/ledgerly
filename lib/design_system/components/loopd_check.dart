import 'package:flutter/widgets.dart';

import '../loopd_colors.dart';
import '../loopd_motion.dart';
import '../loopd_spacing.dart';

/// The task checkbox from the Today mockup (review round 1): a 20 px circle
/// that fills green and draws its tick when done, with a small spring.
/// The ring is red while the task is [overdue].
class LoopdCheck extends StatefulWidget {
  const LoopdCheck({required this.done, required this.onChanged, required this.label, this.overdue = false, super.key});

  final bool done;
  final ValueChanged<bool>? onChanged;

  /// Read by screen readers, such as the task's title.
  final String label;
  final bool overdue;

  @override
  State<LoopdCheck> createState() => _LoopdCheckState();
}

class _LoopdCheckState extends State<LoopdCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _tick = AnimationController(vsync: this, value: widget.done ? 1 : 0);

  @override
  void didUpdateWidget(LoopdCheck old) {
    super.didUpdateWidget(old);
    if (old.done != widget.done) _animate();
  }

  void _animate() {
    final motion = LoopdMotion.of(context);
    if (!widget.done) {
      _tick.value = 0;
      return;
    }
    // The mockup draws the tick after a short delay: 120 ms, then 300 ms.
    final total = motion.tickDelay + motion.tick;
    if (total == Duration.zero) {
      _tick.value = 1;
      return;
    }
    _tick.duration = total;
    _tick.forward(from: 0);
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = LoopdMotion.of(context);
    final done = widget.done;
    final ring = done ? colors.money : (widget.overdue ? colors.danger : colors.textMuted);
    final delayShare =
        motion.tickDelay.inMicroseconds / (motion.tickDelay + motion.tick).inMicroseconds.clamp(1, 1 << 62);
    return Semantics(
      checked: done,
      enabled: widget.onChanged != null,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onChanged == null ? null : () => widget.onChanged!(!done),
        child: SizedBox.square(
          dimension: LoopdSize.minTouch,
          child: Center(
            child: AnimatedScale(
              scale: done ? 1.08 : 1,
              duration: motion.emphasis,
              curve: const Cubic(0.3, 1.6, 0.5, 1),
              child: AnimatedContainer(
                duration: motion.standard,
                curve: LoopdMotion.ease,
                width: LoopdSize.checkCircle,
                height: LoopdSize.checkCircle,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? colors.money : const Color(0x00000000),
                  border: Border.all(color: ring, width: 1.5),
                ),
                child: AnimatedBuilder(
                  animation: _tick,
                  builder: (context, _) => CustomPaint(
                    painter: _TickPainter(
                      progress: Interval(delayShare.clamp(0.0, 0.99), 1, curve: Curves.ease).transform(_tick.value),
                      color: colors.onAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The mockup's tick, `M5 12.5 l4.5 4.5 L19 7.5` in a 24 grid, drawn 12 px
/// wide in the middle of the circle, up to [progress].
class _TickPainter extends CustomPainter {
  _TickPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    const glyph = 12.0;
    final scale = glyph / 24;
    final origin = Offset((size.width - glyph) / 2, (size.height - glyph) / 2);
    Offset p(double x, double y) => origin + Offset(x * scale, y * scale);
    final path = Path()
      ..moveTo(p(5, 12.5).dx, p(5, 12.5).dy)
      ..lineTo(p(9.5, 17).dx, p(9.5, 17).dy)
      ..lineTo(p(19, 7.5).dx, p(19, 7.5).dy);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress || old.color != color;
}
