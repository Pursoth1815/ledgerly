import 'package:hooks_riverpod/hooks_riverpod.dart' show Provider;
import 'package:ledgerly/features/scan_and_pay/services/services.dart';

final qrScannerServiceProvider = Provider<QrScannerService>((ref) {
  final service = QrScannerService();
  ref.onDispose(() => service.dispose());
  return service;
});
