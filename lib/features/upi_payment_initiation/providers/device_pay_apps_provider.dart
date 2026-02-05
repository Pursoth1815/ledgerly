import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/upi_payment_initiation/helpers/upi_chooser.dart';
import 'package:ledgerly/features/upi_payment_initiation/models/upi_apps.dart';

final deviceAppsProvider = FutureProvider<List<UpiApps>>((ref) async {
  final upiChooser = UpiChooser();
  final upiApps = await upiChooser.getUpiAppList();
  return upiApps;
});
