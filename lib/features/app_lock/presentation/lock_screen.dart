import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'providers/app_lock_providers.dart';

/// Loopd is locked (mockup `AppLock.dc.html`, background icons, screen 10n-b,
/// chosen by the owner on 21 Nov 2026): Loopd's own icons rise slowly over a
/// dot-grid paper background, above it the floating lock tile, the title and
/// Unlock. The phone's check opens by itself when the screen first shows.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(appLockProvider.notifier).unlock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final failed = ref.watch(appLockProvider.select((s) => s.failed));
    final checking = ref.watch(appLockProvider.select((s) => s.checking));
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF101319) : const Color(0xFFFAFAF7),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ExcludeSemantics(child: _RisingIcons()),
          // A soft halo of the paper behind the words, so a passing icon never
          // makes them hard to read.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      dark ? const Color(0xFF101319) : const Color(0xFFFAFAF7),
                      (dark ? const Color(0xFF101319) : const Color(0xFFFAFAF7)).withValues(alpha: 0.85),
                      (dark ? const Color(0xFF101319) : const Color(0xFFFAFAF7)).withValues(alpha: 0),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _FloatingTile(),
                    const SizedBox(height: LoopdSpace.xl),
                    Semantics(
                      container: true,
                      header: true,
                      child: Text(
                        'Loopd is locked',
                        textAlign: TextAlign.center,
                        style: LoopdType.pageTitle.copyWith(color: c.textPrimary, fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: LoopdSpace.sm),
                    Semantics(
                      container: true,
                      liveRegion: true,
                      child: Text(
                        failed
                            ? 'Not recognised. Try again, or use your PIN.'
                            : 'Unlock with your fingerprint, face or PIN.',
                        textAlign: TextAlign.center,
                        style: LoopdType.body.copyWith(color: c.textSecondary, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: LoopdSpace.xl),
                    _UnlockButton(busy: checking, onTap: () => ref.read(appLockProvider.notifier).unlock()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: 'Unlock',
      excludeSemantics: true,
      onTap: busy ? null : onTap,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: AnimatedOpacity(
          duration: LoopdMotion.of(context).quick,
          opacity: busy ? 0.6 : 1,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(color: c.vaultSolid, borderRadius: BorderRadius.circular(26)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint_rounded, color: Color(0xFFFFFFFF), size: 22),
                const SizedBox(width: 10),
                Text('Unlock', style: LoopdType.label.copyWith(color: const Color(0xFFFFFFFF), fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The blue lock tile, bobbing gently with a soft glow under it.
class _FloatingTile extends StatefulWidget {
  const _FloatingTile();

  @override
  State<_FloatingTile> createState() => _FloatingTileState();
}

class _FloatingTileState extends State<_FloatingTile> with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LoopdMotion.of(context).reduced) {
      _bob.stop();
    } else if (!_bob.isAnimating) {
      _bob.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tile = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: c.vaultSolid,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: c.vaultSolid.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFFFFFF), size: 40),
    );
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, -10 * Curves.easeInOut.transform(_bob.value)), child: child),
      child: tile,
    );
  }
}

/// One rising icon: what, in which module colour, where, how big, how fast.
class _Floater {
  const _Floater(this.icon, this.tone, this.x, this.size, this.seconds, this.offset);

  final IconData icon;
  final _Tone tone;

  /// Across the screen, 0 to 1.
  final double x;
  final double size;
  final int seconds;

  /// Where in its rise it starts, 0 to 1, so the screen is never empty.
  final double offset;
}

enum _Tone { money, card, travel, notes, lending, cash }

/// A dozen of Loopd's line icons rising slowly over a dot grid, fading in at
/// the bottom and out at the top. Still when the phone asks for less motion.
class _RisingIcons extends StatefulWidget {
  const _RisingIcons();

  static const floaters = [
    _Floater(Icons.currency_rupee_rounded, _Tone.money, 0.06, 46, 21, 0),
    _Floater(Icons.confirmation_number_outlined, _Tone.travel, 0.18, 40, 26, 0.15),
    _Floater(Icons.sticky_note_2_outlined, _Tone.notes, 0.38, 34, 19, 0.47),
    _Floater(Icons.credit_card_rounded, _Tone.card, 0.59, 48, 24, 0.08),
    _Floater(Icons.check_rounded, _Tone.money, 0.77, 36, 18, 0.67),
    _Floater(Icons.shield_outlined, _Tone.travel, 0.85, 42, 23, 0.3),
    _Floater(Icons.calendar_today_outlined, _Tone.lending, 0.28, 38, 22, 0.68),
    _Floater(Icons.account_balance_wallet_outlined, _Tone.cash, 0.69, 40, 20, 0.85),
    _Floater(Icons.currency_rupee_rounded, _Tone.cash, 0.46, 30, 17, 0.35),
    _Floater(Icons.confirmation_number_outlined, _Tone.card, 0.05, 34, 25, 0.76),
    _Floater(Icons.sticky_note_2_outlined, _Tone.lending, 0.82, 30, 21, 0.67),
    _Floater(Icons.check_rounded, _Tone.notes, 0.51, 28, 16, 0.62),
  ];

  @override
  State<_RisingIcons> createState() => _RisingIconsState();
}

class _RisingIconsState extends State<_RisingIcons> with SingleTickerProviderStateMixin {
  // One slow clock; each icon turns it into its own rise.
  late final _clock = AnimationController(vsync: this, duration: const Duration(hours: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LoopdMotion.of(context).reduced) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  (Color, Color) _colours(_Tone tone, LoopdColors c) => switch (tone) {
    _Tone.money => (c.money, c.moneyTint),
    _Tone.card => (c.creditCard, c.creditCardTint),
    _Tone.travel => (c.travel, c.travelTint),
    _Tone.notes => (c.notes, c.notesTint),
    _Tone.lending => (c.lending, c.lendingTint),
    _Tone.cash => (c.cash, c.cashTint),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paper = dark ? const Color(0xFF101319) : const Color(0xFFFAFAF7);
    return LayoutBuilder(
      builder: (context, box) => Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _DotGrid(dark ? const Color(0x12F3F5F9) : const Color(0x1411141B))),
          AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final seconds = _clock.value * 3600;
              return Stack(children: [for (final f in _RisingIcons.floaters) _place(f, seconds, box.biggest, c)]);
            },
          ),
          // Soft fades at the top and bottom, as in the mockup.
          Align(
            alignment: Alignment.topCenter,
            child: _Fade(height: 160, from: paper, to: paper.withValues(alpha: 0)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _Fade(height: 160, from: paper.withValues(alpha: 0), to: paper),
          ),
        ],
      ),
    );
  }

  Widget _place(_Floater f, double seconds, Size screen, LoopdColors c) {
    final progress = (seconds / f.seconds + f.offset) % 1;
    final travel = screen.height + f.size * 2;
    final top = screen.height + f.size - progress * travel;
    final fade = math.min(1.0, math.min(progress / 0.12, (1 - progress) / 0.12));
    final (colour, tint) = _colours(f.tone, c);
    return Positioned(
      left: f.x * (screen.width - f.size),
      top: top,
      child: Opacity(
        opacity: fade.clamp(0, 1),
        child: Transform.rotate(
          angle: progress * 24 * math.pi / 180,
          child: Container(
            width: f.size,
            height: f.size,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(f.size * 0.3)),
            child: Icon(f.icon, color: colour, size: f.size * 0.58),
          ),
        ),
      ),
    );
  }
}

class _Fade extends StatelessWidget {
  const _Fade({required this.height, required this.from, required this.to});

  final double height;
  final Color from;
  final Color to;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [from, to]),
      ),
    ),
  );
}

/// A faint grid of dots, 22 px apart, like notebook paper.
class _DotGrid extends CustomPainter {
  _DotGrid(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = colour;
    for (var y = 11.0; y < size.height; y += 22) {
      for (var x = 11.0; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGrid old) => old.colour != colour;
}
