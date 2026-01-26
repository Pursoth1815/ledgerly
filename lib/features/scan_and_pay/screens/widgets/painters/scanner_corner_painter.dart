import 'package:flutter/material.dart';
import 'package:ledgerly/theme/themes.dart';

class ScannerCornerPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerCornerPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    const double gap = 12.0;
    const double cornerLength = 40.0;
    const double radius = 12.0;
    const double strokeWidth = 3.5;

    final Rect r = scanWindow.inflate(gap);

    final gradient = LinearGradient(colors: [AppColors.primary, AppColors.primaryDark, AppColors.success]);

    final paint = Paint()
      ..shader = gradient.createShader(r)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // ┌ TOP LEFT
    path
      ..moveTo(r.left, r.top + cornerLength)
      ..lineTo(r.left, r.top + radius)
      ..arcToPoint(Offset(r.left + radius, r.top), radius: const Radius.circular(radius), clockwise: true)
      ..lineTo(r.left + cornerLength, r.top);

    // ┐ TOP RIGHT
    path
      ..moveTo(r.right - cornerLength, r.top)
      ..lineTo(r.right - radius, r.top)
      ..arcToPoint(Offset(r.right, r.top + radius), radius: const Radius.circular(radius), clockwise: true)
      ..lineTo(r.right, r.top + cornerLength);

    // ┘ BOTTOM RIGHT
    path
      ..moveTo(r.right, r.bottom - cornerLength)
      ..lineTo(r.right, r.bottom - radius)
      ..arcToPoint(Offset(r.right - radius, r.bottom), radius: const Radius.circular(radius), clockwise: true)
      ..lineTo(r.right - cornerLength, r.bottom);

    // └ BOTTOM LEFT
    path
      ..moveTo(r.left + cornerLength, r.bottom)
      ..lineTo(r.left + radius, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - radius), radius: const Radius.circular(radius), clockwise: true)
      ..lineTo(r.left, r.bottom - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
