import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/upi_payment_initiation/flow/payment_initiation_flow.dart';

final paymentInitiationFlowProvider = Provider<PaymentInitiationFlow>((ref) {
  return PaymentInitiationFlow(ref);
});
