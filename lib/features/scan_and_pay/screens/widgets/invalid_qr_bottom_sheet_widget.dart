import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/scan_and_pay/providers/providers.dart';
import 'package:ledgerly/theme/themes.dart';

class InvalidQrBottomSheet extends HookConsumerWidget {
  final String message;

  const InvalidQrBottomSheet({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(qrScannerServiceProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.gray800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decorative handle at the top
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)),
          ),
          const Icon(Icons.error_outline_rounded, color: AppColors.redAccent, size: 54),
          const SizedBox(height: 16),
          const Text("Invalid QR Code", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                service.initiateScanner();
                Navigator.pop(context);
              },
              child: const Text("Got it", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
