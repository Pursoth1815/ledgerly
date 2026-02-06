import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/upi_payment_initiation/providers/scan_and_pay_flow_provider.dart';
import 'package:ledgerly/features/upi_payment_initiation/screens/sheets/select_payment_app_sheet.dart';
import 'package:ledgerly/shared/widgets/app_bottom_sheet.dart';
import 'package:ledgerly/theme/themes.dart';

class PaymentInitiationScreen extends HookConsumerWidget {
  const PaymentInitiationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.read(paymentInitiationFlowProvider);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // ── Amount Field ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: AppColors.white),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.gray400),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '₹',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.gray300),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Notes Field ───────────────────────────────
          TextField(
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'Notes (max 3 lines)',
              hintStyle: const TextStyle(color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray700,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 32),

          // ── CTA Button ────────────────────────────────
          ElevatedButton(
            onPressed: () {
              showAppBottomSheet(
                context,
                SelectPaymentAppSheet(
                  onAppSelected: (selectedApplication) =>
                      flow.beginTransaction(context, selectedApplication.packageName ?? ''),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Choose payment app', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
