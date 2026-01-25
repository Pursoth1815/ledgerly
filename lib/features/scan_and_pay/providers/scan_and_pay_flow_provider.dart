import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/scan_and_pay/flow/scan_and_pay_flow.dart';
import 'service_providers.dart';

final scanAndPayFlowProvider = Provider<ScanAndPayFlow>((ref) {
  return ScanAndPayFlow(
    scanner: ref.read(qrScannerServiceProvider),
    // later: upiAppService, smsService, etc.
  );
});
