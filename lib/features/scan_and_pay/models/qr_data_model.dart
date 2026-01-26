class QrDataModel {
  final String rawValue;
  final String payeeName;
  final String errorMessage;

  final bool isMerchantQR;
  final bool isValid;

  const QrDataModel({
    this.rawValue = '',
    this.isValid = false,
    this.isMerchantQR = false,
    this.errorMessage = '',
    this.payeeName = '',
  });

  @override
  String toString() {
    return 'QrDataModel('
        'rawValue: $rawValue, '
        'payeeName: $payeeName, '
        'isValid: $isValid'
        ')';
  }

  factory QrDataModel.valid({required String rawValue, required bool isMerchantQR, required String payeeName}) {
    return QrDataModel(rawValue: rawValue, payeeName: payeeName, isValid: true, isMerchantQR: isMerchantQR);
  }

  factory QrDataModel.invalid({String? errorMessage}) {
    return QrDataModel(
      isValid: false,
      errorMessage: errorMessage ?? 'This QR Code is not linked to any UPI Merchant account',
    );
  }
}
