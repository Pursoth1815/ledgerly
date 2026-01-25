import 'package:flutter/material.dart';

import '../services/qr_scanner_service.dart';

class ScanAndPayFlow {
  final QrScannerService scanner;

  ScanAndPayFlow({required this.scanner});

  Future<void> start(BuildContext context) async {
    final rawQr = await scanner.scanOnce(context);
    if (rawQr == null) return;

    // next steps:
    // qr_parser → upi_rules → amount → payment
  }
}
