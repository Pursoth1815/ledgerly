import 'package:flutter/material.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:ledgerly/theme/themes.dart';

class PaymentAppTile extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const PaymentAppTile({super.key, required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray800,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gray700),
                alignment: Alignment.center,
                child: app.iconBytes != null
                    ? Image.memory(app.iconBytes!, width: 40, height: 40)
                    : const Icon(Icons.account_balance_wallet),
              ),

              const SizedBox(height: 12),

              // App name
              Text(
                app.appName ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
