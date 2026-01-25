import 'package:flutter/material.dart';

class UpiConfirmSheet extends StatelessWidget {
  final String qrData;

  const UpiConfirmSheet({super.key, required this.qrData});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(qrData);

    final payee = uri.queryParameters['pn'] ?? 'Unknown';
    final amount = uri.queryParameters['am'] ?? '-';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pay via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Payee: $payee'),
          Text('Amount: ₹$amount'),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // close sheet
                  // await startUpiTransaction(qrData); // 🔥 HERE IT IS USED
                },
                child: const Text('Pay'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
