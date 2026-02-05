import 'package:flutter/material.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/core/navigation/navigation_provider.dart';
import 'package:ledgerly/core/utils/logger.dart';
import 'package:ledgerly/features/upi_payment_initiation/models/upi_apps.dart';
import 'package:ledgerly/features/upi_payment_initiation/providers/device_pay_apps_provider.dart';
import 'package:ledgerly/features/upi_payment_initiation/screens/payment_initiation_screen.dart';

class PaymentInitiationFlow {
  final Ref ref;

  PaymentInitiationFlow(this.ref);

  AsyncValue<List<UpiApps>> get apps => ref.watch(deviceAppsProvider);

  void navigateToPaymentInitiationScreen(BuildContext context) {
    ref.read(navigationProvider).push(const PaymentInitiationScreen());
  }

  Future<void> beginTransaction(BuildContext context, String selectedApplication) async {
    final info = await FlutterDeviceApps.getApp(selectedApplication, includeIcon: true);
    if (info != null && info.packageName != null && info.packageName!.isNotEmpty) {
      AppLogger.d('Version: ${info.versionName} (${info.versionCode})');
      await FlutterDeviceApps.openApp(info.packageName!);
    }
  }
}
