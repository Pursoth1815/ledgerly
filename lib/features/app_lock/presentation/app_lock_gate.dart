import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lock_screen.dart';
import 'providers/app_lock_providers.dart';

/// Puts the lock screen over the whole app, sheets and toasts included, while
/// App lock says so. What is underneath can't be seen, touched or read aloud.
class AppLockGate extends ConsumerWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(appLockProvider.select((s) => s.locked));
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: locked,
          child: IgnorePointer(ignoring: locked, child: child),
        ),
        if (locked) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}
