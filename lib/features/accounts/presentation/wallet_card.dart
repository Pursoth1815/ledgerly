import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_dashed_button.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'account_look.dart';
import 'short_dates.dart';

/// One card in the wallet: a credit card, a bank account or Cash, with what
/// it spent this month.
class WalletItem {
  const WalletItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.bankLine,
    required this.digits,
    required this.spentPaise,
    required this.expenses,
    required this.share,
    this.account,
    this.nextDue,
  });

  /// Credit cards first, then bank accounts, then Cash (mockup A1).
  static List<WalletItem> all({
    required List<LedgerAccount> cards,
    required List<LedgerAccount> banks,
    required SpendingReport month,
    required DateTime now,
  }) {
    final spent = month.byAccount;
    final total = month.totalPaise;
    final counts = <String, int>{};
    for (final entry in month.entries) {
      if (!entry.isRefund) counts[entry.accountId] = (counts[entry.accountId] ?? 0) + 1;
    }
    WalletItem item(String id, AccountKind kind, String name, String bank, String digits, {LedgerAccount? account}) {
      final paise = spent[id] ?? 0;
      return WalletItem(
        id: id,
        kind: kind,
        name: name,
        bankLine: bank,
        digits: digits,
        spentPaise: paise,
        expenses: counts[id] ?? 0,
        share: total <= 0 ? 0 : paise / total,
        account: account,
        nextDue: account?.nextBillDue(now),
      );
    }

    return [
      for (final a in cards)
        item(a.id, a.kind, a.nickname, a.bankName ?? '', a.last4 == null ? '' : '•••• ${a.last4}', account: a),
      for (final a in banks)
        item(a.id, a.kind, a.nickname, a.bankName ?? '', a.last4 == null ? '' : 'A/C •• ${a.last4}', account: a),
      item(SystemAccounts.cash, AccountKind.cash, 'Cash', 'Paid in cash', ''),
    ];
  }

  final String id;
  final AccountKind kind;
  final String name;
  final String bankLine;
  final String digits;
  final int spentPaise;
  final int expenses;

  /// Of this month's spending, 0 to 1.
  final double share;

  /// Null for Cash.
  final LedgerAccount? account;

  /// A credit card's next bill, when it has a due day.
  final DateTime? nextDue;

  bool get isCard => kind == AccountKind.creditCard;
  bool get isBank => kind == AccountKind.bank;
  bool get isCash => kind == AccountKind.cash;

  String get subLine => nextDue == null ? bankLine : '$bankLine · Due ${shortDay(nextDue!)}';

  String get label =>
      '$name, ${formatRupees(spentPaise)} spent this month'
      '${nextDue == null ? '' : ', bill due ${shortDay(nextDue!)}'}';
}

/// A card in the stack. A credit card has a gold chip, tap-to-pay waves and
/// soft circles; a bank account a bank icon and a fading dot grid; Cash is
/// sky blue with a dashed edge (mockup `Wallet.dc.html`).
class WalletCard extends StatelessWidget {
  const WalletCard({required this.item, required this.onTap, this.overlaps = true, super.key});

  static const height = 176.0;
  static const _radius = 22.0;

  final WalletItem item;
  final VoidCallback? onTap;

  /// Lies over the card above it, so it casts a soft shadow on it.
  final bool overlaps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = item.isCash ? Color.alphaBlend(c.cashTint, c.background) : bankColour(item.account?.bankName, c);
    final fg = item.isCash ? c.textPrimary : const Color(0xFFFFFFFF);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: overlaps ? const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, -3))] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.isCard) const RepaintBoundary(child: CustomPaint(painter: _CirclesPainter())),
            if (item.isBank) const RepaintBoundary(child: CustomPaint(painter: _DotGridPainter())),
            if (item.isCash) CustomPaint(painter: LoopdDashedBorder(c.cash, _radius)),
            if (item.isCard)
              const Positioned(right: 18, top: 92, width: 24, height: 24, child: CustomPaint(painter: _WavesPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(LoopdSpace.lg, 12, LoopdSpace.lg, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _Lead(item: item),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LoopdType.heading.copyWith(color: fg),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LoopdType.caption.copyWith(
                                color: fg.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: LoopdSpace.sm),
                      Text(formatRupees(item.spentPaise), style: LoopdType.amount.copyWith(color: fg, fontSize: 17)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.digits,
                          maxLines: 1,
                          style: LoopdType.code.copyWith(
                            color: fg,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isCash ? c.cash : const Color(0x38FFFFFF),
                          borderRadius: BorderRadius.circular(LoopdRadius.pill),
                        ),
                        child: Text(
                          item.isCard ? 'Credit card' : (item.isBank ? 'UPI' : 'Cash'),
                          style: LoopdType.micro.copyWith(
                            color: item.isCash ? c.onAccent : const Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      child: LoopdPressable(onTap: onTap, label: item.label, pressedScale: 0.985, child: card),
    );
  }
}

class _Lead extends StatelessWidget {
  const _Lead({required this.item});

  final WalletItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (item.isBank) {
      return Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
        child: const Icon(Icons.account_balance_outlined, size: 20, color: Color(0xFFFFFFFF)),
      );
    }
    if (item.isCash) {
      return Container(
        width: 38,
        height: 30,
        decoration: BoxDecoration(color: c.cash, borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.payments_outlined, size: 19, color: c.onAccent),
      );
    }
    const line = Color(0x99785000);
    return Container(
      width: 38,
      height: 30,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color(0xFFFCD34D), borderRadius: BorderRadius.circular(7)),
      child: const Stack(
        children: [
          Positioned(left: 0, right: 0, top: 14, height: 1.5, child: ColoredBox(color: line)),
          Positioned(left: 12, top: 0, bottom: 0, width: 1.5, child: ColoredBox(color: line)),
          Positioned(left: 24, top: 0, bottom: 0, width: 1.5, child: ColoredBox(color: line)),
        ],
      ),
    );
  }
}

/// Two large soft circles on the right of a credit card.
class _CirclesPainter extends CustomPainter {
  const _CirclesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.max(size.width / 350, size.height / 176);
    final dx = (size.width - 350 * scale) / 2;
    final dy = (size.height - 176 * scale) / 2;
    Offset at(double x, double y) => Offset(dx + x * scale, dy + y * scale);
    canvas
      ..drawCircle(at(292, 26), 112 * scale, Paint()..color = const Color(0x1CFFFFFF))
      ..drawCircle(at(352, 150), 104 * scale, Paint()..color = const Color(0x2B000000));
  }

  @override
  bool shouldRepaint(_CirclesPainter oldDelegate) => false;
}

/// A fine grid of dots on a bank account, fading in from the left.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const _gap = 11.0;
  static const _radius = 1.3;

  @override
  void paint(Canvas canvas, Size size) {
    // The direction of the fade: 105 degrees, as in the mockup.
    const angle = 105 * math.pi / 180;
    final along = Offset(math.sin(angle), -math.cos(angle));
    final length = (size.width * along.dx).abs() + (size.height * along.dy).abs();
    final paint = Paint();
    for (var y = _gap / 2; y < size.height; y += _gap) {
      for (var x = _gap / 2; x < size.width; x += _gap) {
        final position = ((x - size.width / 2) * along.dx + (y - size.height / 2) * along.dy) / length + 0.5;
        final strength = ((position - 0.38) / 0.62).clamp(0.0, 1.0);
        if (strength == 0) continue;
        paint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.42 * strength);
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}

/// The tap-to-pay waves on a credit card.
class _WavesPainter extends CustomPainter {
  const _WavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final paint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * unit
      ..strokeCap = StrokeCap.round;
    for (final (x, top, bottom, radius) in const [
      (6.0, 8.0, 16.0, 6.0),
      (10.5, 5.5, 18.5, 10.0),
      (15.0, 3.0, 21.0, 14.0),
    ]) {
      final path = Path()
        ..moveTo(x * unit, top * unit)
        ..arcToPoint(Offset(x * unit, bottom * unit), radius: Radius.circular(radius * unit));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavesPainter oldDelegate) => false;
}
