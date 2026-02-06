import 'package:flutter_device_apps/flutter_device_apps.dart' show FlutterDeviceApps, AppInfo;
import 'package:ledgerly/core/utils/logger.dart';
import 'package:ledgerly/features/upi_payment_initiation/helpers/upi_helper.dart';

class UpiChooser {
  final List<String> verifiedUpiPackages = [
    UpiAppsHelper.allBank.packageName,
    UpiAppsHelper.amazonPay.packageName,
    UpiAppsHelper.axisPay.packageName,
    UpiAppsHelper.barodaPay.packageName,
    UpiAppsHelper.bhim.packageName,
    UpiAppsHelper.centUpi.packageName,
    UpiAppsHelper.cointab.packageName,
    UpiAppsHelper.corpUpi.packageName,
    UpiAppsHelper.dcbUpi.packageName,
    UpiAppsHelper.finoBPay.packageName,
    UpiAppsHelper.freecharge.packageName,
    UpiAppsHelper.googlePay.packageName,
    UpiAppsHelper.iMobileICICI.packageName,
    UpiAppsHelper.indusPay.packageName,
    UpiAppsHelper.khaaliJeb.packageName,
    UpiAppsHelper.mahaUpi.packageName,
    UpiAppsHelper.mobikwik.packageName,
    UpiAppsHelper.orientalPay.packageName,
    UpiAppsHelper.paytm.packageName,
    UpiAppsHelper.paywiz.packageName,
    UpiAppsHelper.phonePe.packageName,
    UpiAppsHelper.psb.packageName,
    UpiAppsHelper.sbiPay.packageName,
    UpiAppsHelper.yesPay.packageName,
  ];

  List<AppInfo>? installedApps;
  List<AppInfo> upiAppsMapList = [];

  Future<List<AppInfo>> getUpiAppList({String? pkgName}) async {
    try {
      upiAppsMapList.clear();

      final apps = await FlutterDeviceApps.listApps(includeIcons: true, includeSystem: false);

      return apps.where((app) => verifiedUpiPackages.contains(app.packageName)).toList();
    } catch (e) {
      AppLogger.e('isAppAvailable | e: $e');
      return upiAppsMapList;
    }
  }
}
