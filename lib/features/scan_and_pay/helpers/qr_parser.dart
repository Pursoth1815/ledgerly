import 'package:ledgerly/core/utils/logger.dart';
import 'package:ledgerly/features/scan_and_pay/models/qr_data_model.dart';

class QrParser {
  static QrDataModel parse(String rawValue) {
    Uri? uri;

    try {
      uri = Uri.parse(rawValue);

      if (uri.scheme != 'upi') {
        return QrDataModel.invalid(errorMessage: 'Unsupported QR format. Please scan a valid UPI QR code.');
      }

      final params = uri.queryParameters;

      final pa = params['pa'] ?? ''; // Payee address
      final pn = params['pn'] ?? ''; // Payee name

      bool isMerchantQR = false;

      if (pa.isEmpty) {
        return QrDataModel.invalid(errorMessage: 'Invalid payment details. Merchant information is missing.');
      }

      final merchantRegex = RegExp(
        r'(@okbiz|@ptys|@paytmqr|@ybl|@ibl|@axl|@res\.bpe|@bharatpe|@pz|@freecharge|@cms)',
        caseSensitive: false,
      );

      isMerchantQR = merchantRegex.hasMatch(pa);

      return QrDataModel.valid(rawValue: rawValue, payeeName: pn, isMerchantQR: isMerchantQR);
    } catch (e, st) {
      AppLogger.e('QR Parsing Error: - $e', tag: 'QR_PARSER', stackTrace: st);
      return QrDataModel.invalid(errorMessage: 'Unable to read QR code. Please try again or ensure it is well-lit.');
    }
  }
}
