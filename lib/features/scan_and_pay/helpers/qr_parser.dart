
Uri injectAmountIntoUpi({required Uri originalUri, required String amount}) {
  final params = Map<String, String>.from(originalUri.queryParameters);

  // ✅ Inject amount
  params['am'] = amount;
  params['cu'] = 'INR';

  params['tn'] = 'Ledgerly payment';

  return Uri(scheme: originalUri.scheme, host: originalUri.host, queryParameters: params);
}
