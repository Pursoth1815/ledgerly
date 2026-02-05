import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/upi_payment_initiation/providers/scan_and_pay_flow_provider.dart';

class PaymentInitiationScreen extends HookConsumerWidget {
  const PaymentInitiationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(paymentInitiationFlowProvider);

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shrinkWrap: true,
        itemCount: flow.apps.asData?.value.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.2,
          crossAxisCount: 4,
        ),
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              // AppLogger.d(appsList[index].appUri);
            },
            child: SizedBox(
              height: 80,
              width: 80,
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Image.network(appsList[index].iconUrl!, height: 42),
                      // Text('${appsList[index].displayName}'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
