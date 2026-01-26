import 'package:flutter/material.dart';

class ScannerMaskPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerMaskPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(35)));

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    canvas.drawPath(Path.combine(PathOperation.difference, background, cutout), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
