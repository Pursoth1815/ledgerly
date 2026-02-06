import 'package:flutter/material.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/upi_payment_initiation/providers/device_pay_apps_provider.dart';
import 'package:ledgerly/features/upi_payment_initiation/screens/widgets/payment_app_shimmer.dart';
import 'package:ledgerly/features/upi_payment_initiation/screens/widgets/payment_app_tile.dart';

class SelectPaymentAppSheet extends HookConsumerWidget {
  final void Function(AppInfo app) onAppSelected;

  const SelectPaymentAppSheet({super.key, required this.onAppSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(deviceAppsProvider);

    final controller = useAnimationController(duration: const Duration(milliseconds: 600));

    // Start animation once on mount
    useEffect(() {
      if (appsAsync.hasValue) {
        controller
          ..reset()
          ..forward();
      }
      return null;
    }, [appsAsync]);

    return appsAsync.when(
      data: (apps) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final animation = CurvedAnimation(
              parent: controller,
              curve: Interval(index / apps.length, 1, curve: Curves.easeOutBack),
            );

            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: PaymentAppTile(app: apps[index], onTap: () => onAppSelected(apps[index])),
              ),
            );
          },
        );
      },

      loading: () => const PaymentAppShimmer(),

      error: (error, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load payment apps', style: Theme.of(context).textTheme.bodyMedium),
        );
      },
    );
  }
}
