import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/shell/loopd_tab_bar.dart';
import 'package:loopd/core/security/device_auth.dart';
import 'package:loopd/core/settings/app_lock_setting.dart';
import 'package:loopd/design_system/components/loopd_switch.dart';
import 'package:loopd/features/app_lock/app_lock.dart';

import '../../support/fake_device_auth.dart';
import '../../support/pump_loopd_app.dart';

/// App lock over the whole app, with the phone's check faked.
void main() {
  /// The phone's "Remove animations": the rising icons hold still, so the app
  /// can settle (they move for ever otherwise).
  void stillMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Future<void> away(WidgetTester tester, {required void Function() pass}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    pass();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  // The lock screen's icons move for ever; settle with a fixed number of frames.
  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('with App lock off, Loopd opens straight away and screenshots work', (tester) async {
    final device = FakeDeviceAuth();
    await pumpLoopdApp(tester, device: device);
    expect(find.byType(LockScreen), findsNothing);
    expect(device.private, isFalse);
  });

  testWidgets('with App lock on, Loopd starts locked and the check opens by itself', (tester) async {
    stillMotion(tester);
    final device = FakeDeviceAuth()..passes = false;
    await pumpLoopdApp(tester, device: device, appLock: const AppLockSettings(enabled: true));
    await frames(tester);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(device.calls, ['check'], reason: 'asked once, by itself');
    expect(device.private, isTrue, reason: 'hidden in recents, no screenshots');
    expect(find.text('Not recognised. Try again, or use your PIN.'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(LoopdTabBar), matching: find.text('Money')).hitTestable(),
      findsNothing,
      reason: 'nothing underneath can be touched',
    );

    device.passes = true;
    await tester.tap(find.bySemanticsLabel('Unlock'));
    await frames(tester);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('it locks again only after the chosen time away', (tester) async {
    stillMotion(tester);
    var now = DateTime(2026, 11, 21, 9);
    final device = FakeDeviceAuth();
    await pumpLoopdApp(
      tester,
      device: device,
      appLock: const AppLockSettings(enabled: true, afterMinutes: 5),
      lockClock: () => now,
    );
    await frames(tester);
    expect(find.byType(LockScreen), findsNothing, reason: 'the fake check passed at start');

    await away(tester, pass: () => now = now.add(const Duration(minutes: 4)));
    expect(find.byType(LockScreen), findsNothing, reason: '4 minutes is under 5');
    device.passes = false; // so the check that opens by itself leaves it locked
    await away(tester, pass: () => now = now.add(const Duration(minutes: 5)));
    await frames(tester);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(device.calls, ['check', 'check'], reason: 'at start, and again after 5 minutes');
  });

  testWidgets('a picker Loopd opens itself does not count as being away', (tester) async {
    stillMotion(tester);
    var now = DateTime(2026, 11, 21, 9);
    final device = FakeDeviceAuth();
    await pumpLoopdApp(
      tester,
      device: device,
      appLock: const AppLockSettings(enabled: true, afterMinutes: 0),
      lockClock: () => now,
    );
    await frames(tester);
    device.passes = false; // a wrong lock would stay on screen
    await tester.runAsync(
      () => OutsideActivity.during(() async {
        await away(tester, pass: () => now = now.add(const Duration(minutes: 1)));
      }),
    );
    await frames(tester);
    expect(find.byType(LockScreen), findsNothing);
    expect(device.calls, ['check'], reason: 'only the one at start');
  });

  testWidgets('the sheet turns it on after one check, and the More row says so', (tester) async {
    final device = FakeDeviceAuth();
    await pumpLoopdApp(tester, device: device);
    await tester.tap(find.descendant(of: find.byType(LoopdTabBar), matching: find.text('More')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsOneWidget);
    await tester.tap(find.text('App lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((w) => w is LoopdSwitch && w.label == 'Lock Loopd'));
    await tester.pumpAndSettle();
    expect(device.calls, ['check']);
    expect(device.private, isTrue);
    expect(find.text('On · asks after 1 min away'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('5 min'));
    await tester.pumpAndSettle();
    expect(find.text('On · asks after 5 min away'), findsOneWidget);
  });

  testWidgets('a phone with no screen lock cannot turn it on, and says why', (tester) async {
    final device = FakeDeviceAuth()..hasScreenLock = false;
    await pumpLoopdApp(tester, device: device);
    await tester.tap(find.descendant(of: find.byType(LoopdTabBar), matching: find.text('More')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('App lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((w) => w is LoopdSwitch && w.label == 'Lock Loopd'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your phone has no screen lock yet'), findsOneWidget);
    expect(device.private, isNot(isTrue));
  });
}
