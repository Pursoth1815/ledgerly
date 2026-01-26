import 'package:flutter/material.dart';
import 'package:ledgerly/features/scan_and_pay/models/qr_data_model.dart';
import 'package:ledgerly/features/scan_and_pay/screens/scan_qr_screen.dart';
import 'package:ledgerly/features/scan_and_pay/services/services.dart';

class ScanAndPayFlow {
  final QrScannerService scanner;

  ScanAndPayFlow({required this.scanner});

  Future<void> beginScan(BuildContext context) async {
    final qrData = await Navigator.push<QrDataModel?>(context, MaterialPageRoute(builder: (_) => const ScanQrScreen()));

    if (qrData == null) return;
    //There is  ann issue with QR code // INvalid QR Cdie top Icon !
    // We are unable to verify the UPIID Pls scn theqr code again

    // next:
    // parse QR
    // decide UPI / P2P
    // navigate to amount screen
  }
}
