import 'package:flutter/material.dart';

import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import '../../accounts/accounts.dart';
import 'category_sheet.dart';
import 'spending_period.dart';

// The parts the Money tab and its Show all sheet share (mockups
// `Money.dc.html` and `MoneyAll.dc.html`).

/// Where money is spent from: a bank account, a card or Cash, as the
/// "Spent from" row and the sheet's top card show it.
class SpendSource {
  const SpendSource({required this.id, required this.name, required this.kind, required this.tail, this.bankName});

  final String id;
  final String name;
  final AccountKind kind;

  /// "••2210" for a bank account, "•••• 4417" for a card, "Paid in cash".
  final String tail;
  final String? bankName;

  /// "UPI", "CARD" or "IN HAND", in the card's corner.
  String get kindLabel => switch (kind) {
    AccountKind.creditCard => 'CARD',
    AccountKind.cash => 'IN HAND',
    _ => 'UPI',
  };

  Color background(LoopdColors c) => kind == AccountKind.cash ? c.cashTint : bankColour(bankName, c);
  Color foreground(LoopdColors c) => kind == AccountKind.cash ? c.textPrimary : const Color(0xFFFFFFFF);

  /// Bank accounts, then cards, then Cash; then any removed account
  /// that still has spending in [report], under the name it was saved with.
  static List<SpendSource> all({
    required List<LedgerAccount> banks,
    required List<LedgerAccount> cards,
    required SpendingReport report,
  }) {
    SpendSource of(LedgerAccount a) => SpendSource(
      id: a.id,
      name: a.nickname,
      kind: a.kind,
      bankName: a.bankName,
      tail: a.last4 == null
          ? (a.bankName ?? '')
          : (a.kind == AccountKind.creditCard ? '•••• ${a.last4}' : '••${a.last4}'),
    );
    final sources = [
      ...banks.map(of),
      ...cards.map(of),
      const SpendSource(id: SystemAccounts.cash, name: 'Cash', kind: AccountKind.cash, tail: 'Paid in cash'),
    ];
    final known = {for (final s in sources) s.id};
    for (final e in report.entries) {
      if (known.add(e.accountId)) {
        sources.add(SpendSource(id: e.accountId, name: e.accountName, kind: e.method.fundingKind, tail: 'Removed'));
      }
    }
    return sources;
  }
}

/// A category's look by id; one that is gone (only reachable by an undo)
/// shows as plain "Category".
LedgerCategory categoryLook(String id, List<LedgerCategory> categories) =>
    categories.where((k) => k.id == id).firstOrNull ??
    LedgerCategory(id: id, name: 'Category', colour: 24, icon: 'dots');

/// One category's share of a total: tile, name, amount, a bar and the share.
class CategoryShareRow extends StatelessWidget {
  const CategoryShareRow({
    required this.category,
    required this.paise,
    required this.totalPaise,
    required this.largestPaise,
    super.key,
  });

  final LedgerCategory category;
  final int paise;
  final int totalPaise;

  /// The biggest category's amount, which fills the bar.
  final int largestPaise;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final colour = LoopdCategoryColours.expenseAt(category.colour);
    final share = totalPaise <= 0 ? 0 : (paise * 100 / totalPaise).round();
    final fill = largestPaise <= 0 ? 0.0 : (paise / largestPaise).clamp(0.02, 1.0);
    final amount = formatRupees(paise);
    return Semantics(
      container: true,
      label: '${category.name}, $amount, $share percent',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: LoopdSpace.sm),
          child: Row(
            children: [
              CategoryTile(colour: category.colour, icon: category.icon, size: 36),
              const SizedBox(width: LoopdSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LoopdType.bodyStrong.copyWith(color: c.textPrimary),
                          ),
                        ),
                        Text(amount, style: LoopdType.amount.copyWith(color: c.textPrimary, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(
                              children: [
                                Container(height: 6, color: c.surfaceRaised),
                                FractionallySizedBox(
                                  widthFactor: fill,
                                  child: Container(height: 6, color: colour),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$share%',
                            textAlign: TextAlign.right,
                            style: LoopdType.micro.copyWith(color: c.textMuted, fontWeight: FontWeight.w700),
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
      ),
    );
  }
}

/// A bordered box of rows with hairlines between them.
class SpendingBox extends StatelessWidget {
  const SpendingBox({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            child,
          ],
        ],
      ),
    );
  }
}

/// Expenses and refunds by day, newest first, each day with its total.
/// Tapping a purchase or a refund calls [onEdit].
class SpendingList extends StatelessWidget {
  const SpendingList({
    required this.entries,
    required this.categories,
    required this.now,
    required this.onEdit,
    super.key,
  });

  final List<SpendingEntry> entries;
  final List<LedgerCategory> categories;
  final DateTime now;
  final ValueChanged<SpendingEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final days = <String, List<SpendingEntry>>{};
    for (final e in entries) {
      (days[e.localDate] ??= []).add(e);
    }
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, MapEntry(key: day, value: items)) in days.entries.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            _DayHeader(
              label: dayLabel(day, now),
              // A day with only refunds has nothing counted in it.
              total: items.every((e) => e.isRefund) ? null : items.fold(0, (sum, e) => sum! + e.countedPaise),
            ),
            for (final e in items)
              _EntryRow(entry: e, category: categoryLook(e.categoryId, categories), onEdit: () => onEdit(e)),
          ],
        ],
      ),
    );
  }
}

/// "Today · Sun 15 Nov", "Yesterday · Sat 14 Nov" or "Fri 13 Nov".
String dayLabel(String localDate, DateTime now) {
  final date = DateTime.parse(localDate);
  final today = DateTime(now.year, now.month, now.day);
  final short =
      '${weekdayNames[date.weekday - 1].substring(0, 3)} ${date.day} ${monthNames[date.month - 1].substring(0, 3)}';
  if (date == today) return 'Today · $short';
  if (date == DateTime(today.year, today.month, today.day - 1)) return 'Yesterday · $short';
  return short;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.total});

  final String label;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = LoopdType.caption.copyWith(color: c.textMuted, fontFeatures: const [FontFeature.tabularFigures()]);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(LoopdSpace.lg, LoopdSpace.md, LoopdSpace.lg, LoopdSpace.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            if (total != null) Text(formatRupees(total!), style: style),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.category, required this.onEdit});

  final SpendingEntry entry;
  final LedgerCategory category;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = entry;
    final methodColour = switch (e.method) {
      PaymentMethod.creditCard => c.creditCard,
      PaymentMethod.cash => c.cash,
      _ => c.money,
    };
    final how = switch (e.method) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.creditCard => e.channel == 'upi_qr' ? '${e.accountName} · UPI QR' : e.accountName,
      _ => 'UPI · ${e.accountName}',
    };
    final String title;
    final String sub;
    final String amount;
    String? tag;
    if (e.isRefund) {
      title = e.merchant == null ? 'Refund' : 'Refund · ${e.merchant}';
      final bought = e.originalDate == null ? null : DateTime.parse(e.originalDate!);
      final back = DateTime.parse(e.localDate);
      sub = [
        'Back to ${e.method == PaymentMethod.cash ? 'Cash' : e.accountName}',
        if (bought != null) 'bought ${bought.day} ${monthNames[bought.month - 1].substring(0, 3)}',
      ].join(' · ');
      amount = '+${formatRupees(e.amountPaise)}';
      // It counts in its purchase's month (owner, 18 Nov 2026).
      if (bought != null && (bought.month != back.month || bought.year != back.year)) {
        tag = 'Counts in ${monthNames[bought.month - 1].substring(0, 3)}';
      }
    } else {
      title = e.merchant ?? category.name;
      sub = '${category.name} · $how';
      amount = formatRupees(e.amountPaise);
      if (e.refundedPaise > 0) tag = '${formatRupees(e.refundedPaise)} refunded';
    }
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 6),
        child: Row(
          children: [
            if (e.isRefund)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: c.moneyTint, borderRadius: BorderRadius.circular(36 * 0.32)),
                child: Icon(Icons.undo_rounded, size: 19, color: c.money),
              )
            else
              CategoryTile(colour: category.colour, icon: category.icon, size: 36),
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LoopdType.bodyStrong.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: methodColour, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: LoopdSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: LoopdType.amount.copyWith(color: e.isRefund ? c.money : c.textPrimary, fontSize: 15),
                ),
                if (tag != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.sm, vertical: 1),
                    decoration: BoxDecoration(
                      color: c.surfaceRaised,
                      borderRadius: BorderRadius.circular(LoopdRadius.pill),
                    ),
                    child: Text(
                      tag,
                      style: LoopdType.micro.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
    final label = e.isRefund
        ? '$title, $amount, $sub${tag == null ? '' : ', ${tag.toLowerCase()}'}. Edit'
        : '$title, $amount, $sub${tag == null ? '' : ', $tag'}. Edit';
    return LoopdPressable(onTap: onEdit, label: label, pressedScale: 1, child: row);
  }
}

/// The big card of one account, card or Cash, or of them all, on top
/// of the Show all sheet.
class SpendSourceCard extends StatelessWidget {
  const SpendSourceCard({required this.source, required this.paise, required this.caption, super.key});

  /// Null for all accounts and cards.
  final SpendSource? source;
  final int paise;

  /// "Spent in November" and so on.
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = source;
    final bg = s == null ? c.surfaceRaised : s.background(c);
    final fg = s == null ? c.textPrimary : s.foreground(c);
    final soft = fg.withValues(alpha: 0.85);
    final name = s?.name ?? 'All accounts and cards';
    return Semantics(
      container: true,
      label: '$name, ${formatRupees(paise)}, ${caption.toLowerCase()}',
      excludeSemantics: true,
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(LoopdRadius.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LoopdType.bodyStrong.copyWith(color: fg, fontWeight: FontWeight.w800),
                  ),
                ),
                if (s != null)
                  Text(
                    s.bankName ?? s.kindLabel,
                    style: LoopdType.micro.copyWith(color: soft, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            Text(formatRupees(paise), style: LoopdType.amountLarge.copyWith(color: fg, fontSize: 26)),
            Row(
              children: [
                Expanded(
                  child: Text(s?.tail ?? '', style: LoopdType.code.copyWith(color: soft, fontSize: 12)),
                ),
                Text(caption, style: LoopdType.micro.copyWith(color: soft)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small card in the "Spent from" row: the account's colour, its name,
/// the period's total and its last digits. Choosing one filters the tab.
class SpendSourceChip extends StatelessWidget {
  const SpendSourceChip({
    required this.source,
    required this.paise,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    super.key,
  });

  final SpendSource source;
  final int paise;
  final bool selected;

  /// Another one is chosen.
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    final fg = source.foreground(c);
    final soft = fg.withValues(alpha: 0.85);
    return LoopdPressable(
      onTap: onTap,
      selected: selected,
      label: '${source.name}, ${formatRupees(paise)}',
      child: AnimatedOpacity(
        duration: motion.quick,
        opacity: dimmed ? 0.5 : 1,
        child: AnimatedContainer(
          duration: motion.quick,
          width: 128,
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.md, vertical: 10),
          decoration: BoxDecoration(
            color: source.background(c),
            borderRadius: BorderRadius.circular(LoopdRadius.inner),
            boxShadow: selected
                ? [BoxShadow(color: c.textPrimary, spreadRadius: 4), BoxShadow(color: c.background, spreadRadius: 2)]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LoopdType.small.copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    source.kindLabel,
                    style: LoopdType.micro.copyWith(color: soft, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Text(formatRupees(paise), style: LoopdType.amount.copyWith(color: fg, fontSize: 17)),
              Text(
                source.tail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LoopdType.code.copyWith(color: soft, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
