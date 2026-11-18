import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../loopd_spacing.dart';
import '../loopd_typography.dart';
import 'loopd_pressable.dart';

/// A 48 px pill with a dashed border in [color], for adding something new,
/// such as "+ Add bank account" (mockup `Accounts.dc.html`).
class LoopdDashedButton extends StatelessWidget {
  const LoopdDashedButton({required this.label, required this.color, required this.onTap, super.key});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LoopdPressable(
    onTap: onTap,
    label: label,
    child: CustomPaint(
      painter: _DashedPillPainter(color),
      child: SizedBox(
        height: LoopdSize.button,
        child: Center(
          child: Text('+ $label', style: LoopdType.label.copyWith(color: color)),
        ),
      ),
    ),
  );
}

class _DashedPillPainter extends CustomPainter {
  _DashedPillPainter(this.color);

  final Color color;

  static const _stroke = 1.5;
  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final outline = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    for (final PathMetric metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter oldDelegate) => oldDelegate.color != color;
}
