import 'dart:async';

import 'package:flutter/material.dart';

import '../loopd_colors.dart';
import '../loopd_motion.dart';
import '../loopd_spacing.dart';
import '../loopd_typography.dart';

/// A short message at the top of the screen, such as "Added Savings" (owner,
/// 18 Nov 2026: toasts sit at the top, clear of the capture button and the
/// tab bar). It shows over every page and sheet, one at a time: a new toast
/// replaces the one on screen. It leaves by itself after two seconds, or
/// when tapped or swiped up.
void showLoopdToast(BuildContext context, String message) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _dismiss(_current);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(message: message, onGone: () => _dismiss(entry)),
  );
  _current = entry;
  overlay.insert(entry);
}

/// The toast on screen, if any.
OverlayEntry? _current;

void _dismiss(OverlayEntry? entry) {
  if (entry == null) return;
  if (_current == entry) _current = null;
  // An entry whose overlay has gone (the app was rebuilt) is left alone.
  if (entry.mounted) {
    entry
      ..remove()
      ..dispose();
  }
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.onGone});

  final String message;
  final VoidCallback onGone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  static const _shown = Duration(seconds: 2);

  late final AnimationController _slide = AnimationController(vsync: this);
  Timer? _timer;
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = LoopdMotion.of(context);
    _slide
      ..duration = motion.standard
      ..reverseDuration = motion.quick;
    if (_slide.isDismissed && !_leaving) {
      _slide.forward();
      _timer = Timer(_shown, _leave);
    }
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer?.cancel();
    await _slide.reverse();
    if (mounted) widget.onGone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final curve = CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(LoopdSpace.lg, LoopdSpace.sm, LoopdSpace.lg, 0),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(curve),
            child: FadeTransition(
              opacity: curve,
              child: Semantics(
                liveRegion: true,
                container: true,
                child: GestureDetector(
                  onTap: _leave,
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) < 0) _leave();
                  },
                  child: Material(
                    type: MaterialType.transparency,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: ShapeDecoration(
                          color: c.buttonFill,
                          shape: const StadiumBorder(),
                          shadows: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
                        ),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: LoopdType.label.copyWith(color: c.onButton),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
