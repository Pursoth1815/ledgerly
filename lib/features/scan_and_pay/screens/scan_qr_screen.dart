import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/scan_and_pay/models/qr_data_model.dart';
import 'package:ledgerly/features/scan_and_pay/providers/providers.dart';
import 'package:ledgerly/features/scan_and_pay/screens/widgets/invalid_qr_bottom_sheet_widget.dart';
import 'package:ledgerly/shared/widgets/close_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'widgets/buttons/torch_button.dart';
import 'widgets/scanner_overlay.dart';

class ScanQrScreen extends HookConsumerWidget {
  const ScanQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(qrScannerServiceProvider);

    // ✅ Lifecycle-aware dispose
    useEffect(() {
      service.initiateScanner();
      return null;
    }, const []);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = buildScanWindow(constraints);

          return Stack(
            children: [
              MobileScanner(
                controller: service.controller,
                scanWindow: scanWindow,
                onDetect: (capture) {
                  service.onDetect(capture, (qrData) => _handleProcessedQr(context, qrData));
                },
                overlayBuilder: (_, _) => ScannerOverlay(scanWindow),
              ),

              TorchButton(controller: service.controller, scanWindow: scanWindow),

              const SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(padding: EdgeInsets.all(12), child: CloseIconButton()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Rect buildScanWindow(BoxConstraints constraints) {
    final size = constraints.biggest;
    final scanSize = size.width * 0.7;

    return Rect.fromCenter(center: size.center(const Offset(0, -100)), width: scanSize, height: scanSize);
  }

  Future<void> _handleProcessedQr(BuildContext context, QrDataModel qrData) async {
    if (qrData.isValid) {
      Navigator.pop(context, qrData);
    } else {
      if (context.mounted) {
        await _showInvalidQrSheet(context, qrData.errorMessage);
      }
    }
  }

  Future<void> _showInvalidQrSheet(BuildContext context, String message) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => InvalidQrBottomSheet(message: message),
    );
  }
}
