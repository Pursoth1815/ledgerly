import 'package:flutter/material.dart';
import 'package:ledgerly/core/extensions/extensions.dart';
import 'package:ledgerly/theme/themes.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TorchButton extends HookWidget {
  final MobileScannerController controller;
  final Rect scanWindow;

  const TorchButton({super.key, required this.controller, required this.scanWindow});

  @override
  Widget build(BuildContext context) {
    final isOn = useState(false);

    return Positioned(
      top: scanWindow.bottom + 80,
      left: 0,
      right: 0,
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () {
            controller.toggleTorch();
            isOn.value = !isOn.value;
          },
          child: AnimatedContainer(
            duration: 250.ms,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn.value ? AppColors.primaryDark.withValues(alpha: 0.9) : AppColors.transparent,
              border: Border.all(
                width: isOn.value ? 0 : 1,
                color: isOn.value ? AppColors.transparent : AppColors.white,
              ),
              boxShadow: isOn.value
                  ? [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.6), blurRadius: 16)]
                  : [],
            ),
            child: Icon(isOn.value ? Icons.flash_on : Icons.flash_off, color: AppColors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
