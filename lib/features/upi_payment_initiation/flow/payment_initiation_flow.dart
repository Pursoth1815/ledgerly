import 'package:flutter/material.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/core/utils/logger.dart';
import 'package:ledgerly/features/upi_payment_initiation/screens/sheets/payment_initiation_sheet.dart';
import 'package:ledgerly/shared/widgets/app_bottom_sheet.dart';

class PaymentInitiationFlow {
  final Ref ref;

  PaymentInitiationFlow(this.ref);

  void navigateToPaymentInitiationScreen(BuildContext context) {
    showAppBottomSheet(context, PaymentInitiationScreen());
  }

  Future<void> beginTransaction(BuildContext context, String selectedApplication) async {
    final info = await FlutterDeviceApps.getApp(selectedApplication, includeIcon: true);
    if (info != null && info.packageName != null && info.packageName!.isNotEmpty) {
      AppLogger.d('Version: ${info.versionName} (${info.versionCode})');
      await FlutterDeviceApps.openApp(info.packageName!);
    }
  }
}
