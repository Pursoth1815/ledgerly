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
///
/// With an [action], such as Undo after a save or a delete (mockup
/// `Review.dc.html`), it stays four seconds and shows the action on the
/// right; tapping it runs [onAction] and closes the toast.
void showLoopdToast(BuildContext context, String message, {String? action, VoidCallback? onAction}) {
  assert((action == null) == (onAction == null), 'an action needs both a label and a callback');
  final overlay = Overlay.of(context, rootOverlay: true);
  _dismiss(_current);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(message: message, action: action, onAction: onAction, onGone: () => _dismiss(entry)),
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
  const _Toast({required this.message, required this.onGone, this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback onGone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  static const _shown = Duration(seconds: 2);
  static const _shownWithAction = Duration(seconds: 4);

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
      _timer = Timer(widget.action == null ? _shown : _shownWithAction, _leave);
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
                        // The action's own 44 px touch area sets the height.
                        padding: widget.action == null
                            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 12)
                            : const EdgeInsets.fromLTRB(18, 0, 14, 0),
                        decoration: ShapeDecoration(
                          color: c.buttonFill,
                          shape: const StadiumBorder(),
                          shadows: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
                        ),
                        child: widget.action == null
                            ? Text(
                                widget.message,
                                textAlign: TextAlign.center,
                                style: LoopdType.label.copyWith(color: c.onButton),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(widget.message, style: LoopdType.label.copyWith(color: c.onButton)),
                                  ),
                                  const SizedBox(width: LoopdSpace.md),
                                  Semantics(
                                    button: true,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        widget.onAction!();
                                        _leave();
                                      },
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(minHeight: LoopdSize.minTouch),
                                        child: Center(
                                          child: Text(
                                            widget.action!,
                                            style: LoopdType.label.copyWith(
                                              color: c.onButton,
                                              fontWeight: FontWeight.w800,
                                              decoration: TextDecoration.underline,
                                              decorationColor: c.onButton,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
