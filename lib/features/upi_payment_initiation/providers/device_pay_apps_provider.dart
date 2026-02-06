import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/upi_payment_initiation/helpers/upi_chooser.dart';

final deviceAppsProvider = FutureProvider<List<AppInfo>>((ref) {
  final upiChooser = UpiChooser();
  return upiChooser.getUpiAppList();
});
