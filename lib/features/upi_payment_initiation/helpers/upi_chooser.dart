import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:ledgerly/core/utils/logger.dart';
import 'package:ledgerly/features/upi_payment_initiation/helpers/upi_helper.dart';
import 'package:ledgerly/features/upi_payment_initiation/models/model.dart';

class UpiChooser {
  final List<String> verifiedFuaApps = [
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
  List<AppInfo> androidApps = [
    AppInfo(appName: "G-Pay", packageName: UpiAppsHelper.googlePay.packageName),
    AppInfo(appName: "Paytm", packageName: UpiAppsHelper.paytm.packageName),
    AppInfo(appName: "PhonePe", packageName: UpiAppsHelper.phonePe.packageName),
    AppInfo(appName: "BHIM", packageName: UpiAppsHelper.bhim.packageName),
    AppInfo(appName: "CRED", packageName: 'com.dreamplug.androidapp'),
    AppInfo(appName: "Amazon Pay", packageName: UpiAppsHelper.amazonPay.packageName),
    AppInfo(appName: "My Airtel", packageName: "com.myairtelapp"),
    AppInfo(appName: "Payzapp", packageName: UpiAppsHelper.payZapp.packageName),
    AppInfo(appName: "Mobikwik", packageName: UpiAppsHelper.mobikwik.packageName),
    AppInfo(appName: "Freecharge", packageName: UpiAppsHelper.freecharge.packageName),
  ];

  List<AppInfo> iOSApps = [
    AppInfo(appName: "G-Pay", packageName: "gpay://"),
    AppInfo(appName: "Paytm", packageName: "paytmmp://"),
    AppInfo(appName: "PhonePe", packageName: "phonepe://"),
    AppInfo(appName: "BHIM", packageName: "bhim://"),
    AppInfo(appName: "CRED", packageName: "credpay://"),
    AppInfo(appName: "Amazon Pay", packageName: "amazon://"),
    AppInfo(appName: "My Airtel", packageName: "myairtel://"),
    AppInfo(appName: "Payzapp", packageName: "payzapp://"),
    AppInfo(appName: "Mobikwik", packageName: "mobikwik://"),
    AppInfo(appName: "Freecharge", packageName: "freecharge://"),
  ];

  List<String> upiAndroidIcons = [
    UpiAppsHelper.gpayImg,
    UpiAppsHelper.paytmImg,
    UpiAppsHelper.phonepeImg,
    UpiAppsHelper.bhimImg,
    UpiAppsHelper.credImg,
    UpiAppsHelper.amazonImg,
    UpiAppsHelper.airtelImg,
    UpiAppsHelper.payzappImg,
    UpiAppsHelper.mobikwikImg,
    UpiAppsHelper.freechargeImg,
  ];
  List<String> upiIosIcons = [
    UpiAppsHelper.gpayImg,
    UpiAppsHelper.paytmImg,
    UpiAppsHelper.phonepeImg,
    UpiAppsHelper.bhimImg,
    UpiAppsHelper.credImg,
    UpiAppsHelper.amazonImg,
    UpiAppsHelper.airtelImg,
    UpiAppsHelper.payzappImg,
    UpiAppsHelper.mobikwikImg,
    UpiAppsHelper.freechargeImg,
  ];

  List<UpiApps> upiAppsMapList = [];

  AppCheck appCheck = AppCheck();

  Future<List<UpiApps>> getUpiAppList({String? pkgName}) async {
    try {
      upiAppsMapList.clear();
      if (Platform.isAndroid) {
        for (int i = 0; i < androidApps.length; i++) {
          try {
            await appCheck.checkAvailability(androidApps[i].packageName).then((app) {
              AppLogger.d(app.toString());
              AppLogger.d('upiAndroidIcons[i]: ${upiAndroidIcons[i]}');
              upiAppsMapList.add(
                UpiApps(
                  id: i,
                  displayName: androidApps[i].appName,
                  appUri: androidApps[i].packageName,
                  isAvailable: true,
                  scheme: iOSApps[i].packageName.split(':')[0],
                  iconUrl: upiAndroidIcons[i],
                ),
              );
            });
          } catch (e) {
            AppLogger.e('isAppAvailable | for | e: $e');
          }
          AppLogger.e('$i');
        }
      }
      return upiAppsMapList;
    } catch (e) {
      AppLogger.e('isAppAvailable | e: $e');
      return upiAppsMapList;
    }
  }
}


//   Slack - com.Slack
  // [APP] Brave - com.brave.browser
  // [APP] Calendar - com.google.android.calendar
  // [APP] MyJio - com.jio.myjio
  // [APP] Call of Duty - com.activision.callofduty.shooter
  // [APP] Zomato - com.application.zomato
  // [APP] BookMyShow - com.bt.bms
  // [APP] iMobile - com.csam.icici.bank.imobile
  // [APP] BSNL Selfcare - com.digital.bsnl.selfcare
  // [APP] Gemini - com.google.android.apps.bard
  // [APP] GPay - com.google.android.apps.nbu.paisa.user
  // [APP] Gboard - com.google.android.inputmethod.latin
  // [APP] HDFC Bank App - com.hdfcbank.android.now
  // [APP] IDFC FIRST Bank - com.idfcfirstbank.optimus
  // [APP] LinkedIn - com.linkedin.android
  // [APP] aura - com.moi
  // [APP] Airtel - com.myairtelapp
  // [APP] Groww - com.nextbillion.groww
  // [APP] PhonePe - com.phonepe.app
  // [APP] ledgerly - com.pursoth.ledgerly.dev
  // [APP] RBL MyCard - com.rbl.rblmycard
  // [APP] Tata Neu - com.tatadigital.tcp
  // [APP] Rooms & Exits - Can you Escape room? - com.webelinx.Rooms.Exits.EscapeRoom.FreeEscapeGames
  // [APP] WhatsApp - com.whatsapp
  // [APP] IRCTC Rail Connect - cris.org.in.prs.ima
  // [APP] JioHotstar - in.startv.hotstar
  // [APP] Jupiter - money.jupiter
  // [APP] Telegram - org.telegram.messenger
