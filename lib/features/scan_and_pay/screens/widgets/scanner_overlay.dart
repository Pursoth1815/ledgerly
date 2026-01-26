import 'package:flutter/material.dart';
import 'painters/painters.dart';

class ScannerOverlay extends StatelessWidget {
  final Rect scanWindow;

  const ScannerOverlay(this.scanWindow, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(size: MediaQuery.of(context).size, painter: ScannerMaskPainter(scanWindow)),
        CustomPaint(size: MediaQuery.of(context).size, painter: ScannerCornerPainter(scanWindow)),
      ],
    );
  }
}
