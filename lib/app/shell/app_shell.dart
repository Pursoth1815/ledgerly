import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/loopd_pressable.dart';
import '../../design_system/loopd_colors.dart';
import '../../design_system/loopd_motion.dart';
import '../../features/accounts/accounts.dart';
import '../../features/capture/capture.dart';
import '../../features/expenses/expenses.dart';
import 'capture_button_visibility.dart';
import 'loopd_tab_bar.dart';

/// The five-tab shell (ADR 0003). Each tab keeps its own navigator and history.
///
/// The capture button floats above the tab bar on every tab (proposal
/// section 3) and opens the capture sheet. It steps aside while a sheet or
/// dialog is open ([captureButtonVisibleProvider]).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        navigationShell,
        const Positioned(right: 20, bottom: 20, child: _CaptureButtonSlot()),
      ],
    ),
    bottomNavigationBar: LoopdTabBar(
      currentIndex: navigationShell.currentIndex,
      onSelected: (index) => navigationShell.goBranch(
        index,
        // Tapping the current tab again returns to its first page.
        initialLocation: index == navigationShell.currentIndex,
      ),
    ),
  );
}

/// Shows or hides the capture button with a short fade and shrink. Hidden,
/// it takes no taps and is not read out.
class _CaptureButtonSlot extends ConsumerWidget {
  const _CaptureButtonSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(captureButtonVisibleProvider);
    final duration = LoopdMotion.of(context).quick;
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          child: AnimatedScale(
            scale: visible ? 1 : 0.7,
            duration: duration,
            curve: LoopdMotion.ease,
            child: const CaptureButton(),
          ),
        ),
      ),
    );
  }
}

/// The round capture button from the mockups: 60 px, the strongest neutral,
/// with a plus.
class CaptureButton extends StatelessWidget {
  const CaptureButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LoopdPressable(
      onTap: () => showCaptureSheet(
        context,
        shortcuts: {
          CaptureShortcut.expense: () =>
              showExpenseSheet(context, onAddAccount: (context, kind) => showAddAccountSheet(context, kind: kind)),
        },
      ),
      label: 'Add anything',
      pressedScale: 0.92,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: c.buttonFill, shape: BoxShape.circle),
        child: Icon(Icons.add_rounded, size: 30, color: c.onButton),
      ),
    );
  }
}
