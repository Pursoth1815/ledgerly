import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'bill_due_sheet.dart';
import 'short_dates.dart';
import 'wallet_card.dart';

/// What rises in under an opened card (mockups A2 to A4): the month's
/// spending with its ring, the bill due for a card, and the actions.
/// [progress] is the wallet's open animation, so Back plays it in reverse.
class WalletDetail extends StatelessWidget {
  const WalletDetail({
    required this.item,
    required this.progress,
    required this.now,
    required this.onViewExpenses,
    required this.onDetails,
    super.key,
  });

  final WalletItem item;
  final double progress;
  final DateTime now;
  final VoidCallback? onViewExpenses;

  /// Null for Cash, which has no details.
  final VoidCallback? onDetails;

  static const _easeOut = Cubic(0.22, 0.8, 0.24, 1);

  Widget _rise(int step, Widget child) {
    final start = 0.38 + step * 0.07;
    final value = Interval(start, math.min(start + 0.4, 1), curve: _easeOut).transform(progress);
    return Opacity(
      opacity: value,
      child: Transform.translate(offset: Offset(0, 22 * (1 - value)), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (accent, tint) = item.isCard
        ? (c.creditCard, c.creditCardTint)
        : (item.isBank ? (c.money, c.moneyTint) : (c.cash, c.cashTint));
    final ring = const Interval(0.5, 1, curve: _easeOut).transform(progress);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _rise(0, _SpentTile(item: item, now: now, accent: accent, tint: tint, ring: ring)),
          if (item.nextDue != null) ...[
            const SizedBox(height: LoopdSpace.md),
            _rise(1, _DueTile(item: item, now: now)),
          ],
          const SizedBox(height: LoopdSpace.md),
          _rise(
            2,
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActionRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'View expenses',
                    iconColour: accent,
                    iconTint: tint,
                    onTap: onViewExpenses,
                  ),
                  if (onDetails != null) ...[
                    Divider(height: 1, thickness: 1, color: c.line),
                    _ActionRow(
                      icon: Icons.tune_rounded,
                      label: item.isCard ? 'Card details' : 'Account details',
                      iconColour: c.textPrimary,
                      iconTint: c.surface,
                      onTap: onDetails,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: LoopdSpace.sm),
        ],
      ),
    );
  }
}

class _SpentTile extends StatelessWidget {
  const _SpentTile({
    required this.item,
    required this.now,
    required this.accent,
    required this.tint,
    required this.ring,
  });

  final WalletItem item;
  final DateTime now;
  final Color accent;
  final Color tint;
  final double ring;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amount = formatRupees(item.spentPaise);
    final percent = '${(item.share * 100).round()}%';
    final month = longMonth(now);
    final count = item.expenses == 1 ? '1 expense' : '${item.expenses} expenses';
    return Semantics(
      container: true,
      label: 'Spent in $month, $amount, $count, $percent of your spending',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spent in $month', style: LoopdType.small.copyWith(color: c.textSecondary)),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: LoopdType.amountLarge.copyWith(color: c.textPrimary, fontSize: 32, letterSpacing: -0.5),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    count,
                    style: LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
            SizedBox(
              width: 84,
              height: 84,
              child: CustomPaint(
                painter: _RingPainter(value: item.share * ring, colour: accent, track: accent.withValues(alpha: 0.2)),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(percent, style: LoopdType.amount.copyWith(color: c.textPrimary, fontSize: 17)),
                      Text(
                        'of total',
                        style: LoopdType.micro.copyWith(
                          color: c.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.colour, required this.track});

  final double value;
  final Color colour;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (value > 0) canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, paint..color = colour);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.colour != colour || oldDelegate.track != track;
}

class _DueTile extends StatelessWidget {
  const _DueTile({required this.item, required this.now});

  final WalletItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final due = item.nextDue!;
    final today = DateTime(now.year, now.month, now.day);
    final days = (due.difference(today).inHours / 24).round();
    final colour = days <= 7 ? c.review : c.creditCard;
    final left = days == 0 ? 'Due today' : (days == 1 ? '1 day left' : '$days days left');
    return Semantics(
      container: true,
      label: 'Bill due ${shortDay(due)}, $left',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(LoopdSpace.md, LoopdSpace.md, LoopdSpace.lg, LoopdSpace.md),
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 54,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(13)),
              child: Column(
                children: [
                  Container(
                    height: 18,
                    width: double.infinity,
                    color: colour,
                    alignment: Alignment.center,
                    child: Text(
                      shortMonth(due).toUpperCase(),
                      style: LoopdType.micro.copyWith(
                        color: c.onAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('${due.day}', style: LoopdType.amount.copyWith(color: c.textPrimary, fontSize: 21)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bill due ${shortDay(due)}', style: LoopdType.bodyStrong.copyWith(color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    'Every month on the ${dayOrdinal(item.account!.billDueDay!)}',
                    style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LoopdSpace.sm),
            if (days == 0)
              Text(
                'Today',
                style: LoopdType.bodyStrong.copyWith(color: colour, fontWeight: FontWeight.w800),
              )
            else
              Column(
                children: [
                  Text('$days', style: LoopdType.amount.copyWith(color: colour, fontSize: 22, height: 1.1)),
                  Text(
                    days == 1 ? 'day left' : 'days left',
                    style: LoopdType.micro.copyWith(color: c.textMuted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.iconColour,
    required this.iconTint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColour;
  final Color iconTint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      child: LoopdPressable(
        onTap: onTap,
        label: label,
        pressedScale: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(LoopdSpace.md, 0, LoopdSpace.lg, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: iconTint, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: iconColour),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(label, style: LoopdType.bodyStrong.copyWith(color: c.textPrimary)),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
