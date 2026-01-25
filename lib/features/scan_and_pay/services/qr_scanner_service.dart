import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerService {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  Future<String?> scanOnce(BuildContext context) async {
    _handled = false;

    return await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Scan QR')),
          body: MobileScanner(
            controller: _controller,
            onDetect: (barcodeCapture) {
              if (_handled) return;
              _handled = true;

              final barcode = barcodeCapture.barcodes.first;
              final rawValue = barcode.rawValue;

              if (rawValue != null) {
                _controller.stop();
                Navigator.pop(context, rawValue);
              }
            },
          ),
        ),
      ),
    );
  }

  void dispose() {
    _controller.dispose();
  }
}
