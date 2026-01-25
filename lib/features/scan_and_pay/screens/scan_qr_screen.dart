import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/providers.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ref.read(scanAndPayFlowProvider).start(context);
          },
          child: const Text('Start Scan'),
        ),
      ),
    );
  }
}
