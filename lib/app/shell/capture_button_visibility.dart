import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/routing/route_paths.dart';

part 'capture_button_visibility.g.dart';

// When the floating capture button shows (owner's rule, 18 Nov 2026). It is
// on every tab, and steps aside in two cases:
//
// 1. A full page listed in [captureButtonHiddenOn].
// 2. Any sheet or dialog is open, on any tab or page. [OpenOverlays] counts
//    them through a navigator observer, so a new sheet needs no code of its
//    own to hide the button.

/// Full pages that hide the capture button, by route path. None so far: a
/// page with its own Save button, such as a full-screen form, goes here.
const Set<String> captureButtonHiddenOn = {};

/// Whether the capture button shows now.
@riverpod
bool captureButtonVisible(Ref ref) =>
    ref.watch(openOverlaysProvider) == 0 && !captureButtonHiddenOn.contains(ref.watch(shellLocationProvider));

/// The path of the page on screen, such as `/more`. The router
/// keeps it current.
@Riverpod(keepAlive: true)
class ShellLocation extends _$ShellLocation {
  @override
  String build() => RoutePaths.today;

  void update(String path) => _outsideBuild(() => state = path);
}

/// How many sheets and dialogs are open, across every navigator.
@Riverpod(keepAlive: true)
class OpenOverlays extends _$OpenOverlays {
  @override
  int build() => 0;

  /// A new observer for one navigator; each navigator needs its own. It
  /// counts popup routes: bottom sheets, dialogs and menus.
  NavigatorObserver observer() => _OverlayObserver(this);

  void _change(int by) => _outsideBuild(() => state = max(0, state + by));
}

class _OverlayObserver extends NavigatorObserver {
  _OverlayObserver(this._overlays);

  final OpenOverlays _overlays;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) _overlays._change(1);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) _overlays._change(-1);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) _overlays._change(-1);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute is PopupRoute) _overlays._change(-1);
    if (newRoute is PopupRoute) _overlays._change(1);
  }
}

/// Runs [change] now, or after the frame when the widget tree is building:
/// a navigator can drop a sheet while it rebuilds (after a route change),
/// and providers must not change during a build.
void _outsideBuild(VoidCallback change) {
  final scheduler = SchedulerBinding.instance;
  if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
    scheduler.addPostFrameCallback((_) => change());
  } else {
    change();
  }
}
