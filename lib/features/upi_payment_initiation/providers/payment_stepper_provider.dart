import 'package:hooks_riverpod/hooks_riverpod.dart';

final paymentStepProvider = StateProvider<PaymentStep>((ref) => PaymentStep.summary);

enum PaymentStep { summary, method, result }
