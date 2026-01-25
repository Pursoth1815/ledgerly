import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/services.dart';

final qrScannerServiceProvider = Provider<QrScannerService>((ref) {
  final service = QrScannerService();
  ref.onDispose(service.dispose);
  return service;
});
