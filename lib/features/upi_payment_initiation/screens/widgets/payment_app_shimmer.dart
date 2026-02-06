import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ledgerly/theme/themes.dart';

class PaymentAppShimmer extends StatelessWidget {
  const PaymentAppShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: 8,
      itemBuilder: (_, _) => const PaymentAppShimmerTile(),
    );
  }
}

class PaymentAppShimmerTile extends StatelessWidget {
  const PaymentAppShimmerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray700,
      highlightColor: AppColors.gray600,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.redAccent),
            ),

            const SizedBox(height: 12),

            // App name placeholder
            Container(
              height: 12,
              width: 50,
              decoration: BoxDecoration(color: AppColors.redAccent, borderRadius: BorderRadius.circular(6)),
            ),
          ],
        ),
      ),
    );
  }
}
