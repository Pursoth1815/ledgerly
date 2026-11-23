import 'package:flutter/material.dart';

import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'today_date.dart';

/// Today's Spending card (mockup `Main.dc.html`, screen 1): today and the
/// month so far, split into UPI, Credit Card and Cash. A method with nothing
/// spent is left out, as on the Money tab.
class SpendingCard extends StatelessWidget {
  const SpendingCard({required this.month, required this.now, super.key});

  /// This month's spending so far.
  final SpendingReport month;
  final DateTime now;

  /// A card that has nothing to say is not shown (proposal section 3).
  static bool hasSomething(SpendingReport month) => month.totalPaise > 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = localDay(now);
    final todayPaise = month.entries.where((e) => e.localDate == today).fold(0, (sum, e) => sum + e.countedPaise);
    final methods = month.byMethod;
    final monthLabel = '${monthName(now)} so far';
    Color colour(PaymentMethod m) => switch (m) {
      PaymentMethod.creditCard => c.creditCard,
      PaymentMethod.cash => c.cash,
      _ => c.money,
    };
    String name(PaymentMethod m) => switch (m) {
      PaymentMethod.creditCard => 'Credit Card',
      PaymentMethod.cash => 'Cash',
      _ => 'UPI',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Dot(c.money),
              const SizedBox(width: LoopdSpace.sm),
              Semantics(
                container: true,
                header: true,
                child: Text('Spending', style: LoopdType.bodyStrong.copyWith(color: c.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Figure(label: 'Today', paise: todayPaise),
              ),
              const SizedBox(width: LoopdSpace.md),
              Expanded(
                child: _Figure(label: monthLabel, paise: month.totalPaise),
              ),
            ],
          ),
          if (methods.isNotEmpty) ...[
            const SizedBox(height: 14),
            Semantics(
              container: true,
              label: methods.map((m) => '${name(m.$1)} ${formatRupees(m.$2)}').join(', '),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (final (i, (method, paise)) in methods.indexed) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: paise,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(color: colour(method), borderRadius: BorderRadius.circular(5)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      for (final (method, paise) in methods)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Dot(colour(method)),
                            const SizedBox(width: 6),
                            Text(
                              '${name(method)} ${formatRupees(paise)}',
                              style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.paise});

  final String label;
  final int paise;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: '$label, ${formatRupees(paise)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              formatRupees(paise),
              style: LoopdType.amount.copyWith(color: c.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.colour);

  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
  );
}
