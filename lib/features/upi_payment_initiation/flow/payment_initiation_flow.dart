import 'package:flutter/material.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/core/navigation/navigation_provider.dart';
import 'package:ledgerly/core/utils/logger.dart';
import 'package:ledgerly/features/upi_payment_initiation/providers/providers.dart';
import 'package:ledgerly/features/upi_payment_initiation/screens/payment_screen.dart';

class PaymentInitiationFlow {
  final Ref ref;

  PaymentInitiationFlow(this.ref);

  void navigateToPaymentInitiationScreen(WidgetRef ref) {
    ref.read(paymentStepProvider.notifier).state = PaymentStep.summary;
    ref.read(navigationProvider).push(const PaymentPage());
  }

  Future<void> beginTransaction(BuildContext context, String selectedApplication) async {
    final info = await FlutterDeviceApps.getApp(selectedApplication, includeIcon: true);
    if (info != null && info.packageName != null && info.packageName!.isNotEmpty) {
      AppLogger.d('Version: ${info.versionName} (${info.versionCode})');
      await FlutterDeviceApps.openApp(info.packageName!);
    }
  }
}
