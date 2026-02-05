import 'package:flutter/material.dart';
import 'package:ledgerly/theme/themes.dart';

class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsets contentPadding;
  final bool showDragHandle;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 16, 24, 24),
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.gray800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle) ...[
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
            ],

            Padding(padding: contentPadding, child: child),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAppBottomSheet<T>(
  BuildContext context,
  Widget content, {
  bool showDragHandle = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool allowBackDismiss = true,
  EdgeInsets contentPadding = const EdgeInsets.fromLTRB(24, 16, 24, 24),
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (_) => PopScope(
      canPop: allowBackDismiss,
      child: AppBottomSheet(
        showDragHandle: showDragHandle && enableDrag,
        contentPadding: contentPadding,
        child: content,
      ),
    ),
  );
}
