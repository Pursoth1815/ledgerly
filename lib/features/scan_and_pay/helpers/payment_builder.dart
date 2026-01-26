Future<void> startUpiTransaction(String qrData) async {
  //  final merchantRegex = RegExp(
  //   r'(@okbiz|@ptys|@paytmqr|@ybl|@ibl|@axl|@res\.bpe|@bharatpe|@pz|@freecharge|@cms)',
  //   caseSensitive: false
  // );

  // if (merchantRegex.hasMatch(pa)) return true;
  // final updatedUpiUri = injectAmountIntoUpi(originalUri: Uri.parse(qrData), amount: '1');
  // AppLogger.d("upd qt --  ${updatedUpiUri.toString()}");

  // final uri = Uri.parse(qrData);
  // AppLogger.d("uri --  ${uri.toString()}");
  // await launchUrl(updatedUpiUri, mode: LaunchMode.externalApplication);
}



Uri injectAmountIntoUpi({required Uri originalUri, required String amount}) {
  final params = Map<String, String>.from(originalUri.queryParameters);

  // ✅ Inject amount
  params['am'] = amount;
  params['cu'] = 'INR';

  params['tn'] = 'Ledgerly payment';

  return Uri(scheme: originalUri.scheme, host: originalUri.host, queryParameters: params);
}
