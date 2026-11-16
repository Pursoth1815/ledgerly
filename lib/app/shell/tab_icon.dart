import 'package:flutter/widgets.dart';

import 'app_tab.dart';

/// The tab bar icons, drawn from the mockup's SVG paths (24 by 24, 1.9 stroke,
/// round caps and joins) so they match the design exactly.
class TabIcon extends StatelessWidget {
  const TabIcon({required this.tab, required this.color, super.key});

  final AppTab tab;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size.square(24), painter: _TabIconPainter(tab, color));
}

class _TabIconPainter extends CustomPainter {
  _TabIconPainter(this.tab, this.color);

  final AppTab tab;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in _paths(tab)) {
      canvas.drawPath(path, stroke);
    }
  }

  static List<Path> _paths(AppTab tab) => switch (tab) {
    // M4 10.5L12 4l8 6.5V20H15v-5H9v5H4z
    AppTab.today => [
      _polygon(const [(4, 10.5), (12, 4), (20, 10.5), (20, 20), (15, 20), (15, 15), (9, 15), (9, 20), (4, 20)]),
    ],
    // A card: rect 3,6 18x13 r3, a stripe and a short line.
    AppTab.money => [_rounded(3, 6, 18, 13, 3), _line(3, 10, 21, 10), _line(16, 15, 18, 15)],
    // A ticket with a notch on each side and a dashed tear line.
    AppTab.travel => [
      Path()
        ..moveTo(4, 7)
        ..lineTo(20, 7)
        ..lineTo(20, 10)
        ..arcToPoint(const Offset(20, 14), radius: const Radius.circular(2), clockwise: false)
        ..lineTo(20, 17)
        ..lineTo(4, 17)
        ..lineTo(4, 14)
        ..arcToPoint(const Offset(4, 10), radius: const Radius.circular(2), clockwise: false)
        ..close(),
      for (final y in const [7.0, 11.0, 15.0]) _line(14, y, 14, y + 2),
    ],
    // A page with a folded corner and two lines of text.
    AppTab.planner => [
      _polygon(const [(6, 3), (15, 3), (19, 7), (19, 21), (6, 21)]),
      _line(9, 12, 16, 12),
      _line(9, 16, 14, 16),
    ],
    // Four rounded squares.
    AppTab.more => [
      for (final (x, y) in const [(4.0, 4.0), (13.0, 4.0), (4.0, 13.0), (13.0, 13.0)]) _rounded(x, y, 7, 7, 2),
    ],
  };

  static Path _polygon(List<(double, double)> points) =>
      Path()..addPolygon([for (final (x, y) in points) Offset(x, y)], true);

  static Path _rounded(double x, double y, double width, double height, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(x, y, x + width, y + height, Radius.circular(radius)));

  static Path _line(double x1, double y1, double x2, double y2) => Path()
    ..moveTo(x1, y1)
    ..lineTo(x2, y2);

  @override
  bool shouldRepaint(_TabIconPainter oldDelegate) => oldDelegate.tab != tab || oldDelegate.color != color;
}
