import 'package:ledgerly/core/utils/logger.dart';
import 'package:ledgerly/features/scan_and_pay/helpers/qr_parser.dart';
import 'package:ledgerly/features/scan_and_pay/models/qr_data_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerService {
  final MobileScannerController controller = MobileScannerController();

  ScannerState scannerState = ScannerState.idle;

  void onDetect(BarcodeCapture barcodeCapture, Function(QrDataModel model) onCallBack) {
    stopScanner();

    final rawValue = barcodeCapture.barcodes.first.rawValue;

    QrDataModel? qrData;

    if (rawValue != null) {
      qrData = QrParser.parse(rawValue);
      AppLogger.d(qrData.toString(), tag: "qrData");
    }

    AppLogger.d(rawValue, tag: "rawValue");
    AppLogger.d(qrData, tag: "qrData");

    onCallBack(qrData ?? QrDataModel.invalid());
  }

  void dispose() {
    try {
      stopScanner();
      controller.dispose();
    } catch (e) {
      AppLogger.e('Scanner dispose ignored: $e', tag: 'QR Scanner');
    }
  }

  void initiateScanner() {
    if (scannerState == ScannerState.running) return;
    controller.start();
    scannerState = ScannerState.running;
  }

  void stopScanner() {
    if (scannerState != ScannerState.running) return;
    try {
      controller.stop();
    } catch (e) {
      // 🔥 Ignore platform bug: no active stream to cancel
      AppLogger.e('Scanner stop ignored: $e', tag: 'QR Scanner');
    } finally {
      scannerState = ScannerState.stopped;
    }
  }
}

enum ScannerState { idle, running, stopped }
