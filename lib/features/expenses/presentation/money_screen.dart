import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_segmented.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import '../../accounts/accounts.dart';
import 'expense_sheet.dart';
import 'providers/expense_providers.dart';
import 'spending_parts.dart';
import 'spending_period.dart';
import 'spending_sheet.dart';

/// Opens Accounts and cards; passed in by `app/`, because that sheet adds
/// and removes accounts (architecture rule 3).
typedef OpenAccounts = Future<void> Function(BuildContext context);

/// The Money tab, Expenses segment (mockup `Money.dc.html`, screen 5a):
/// the period's total with its UPI, Credit Card and Cash split, where it was
/// spent from, the top categories and the expenses by day. Refunds count in
/// their purchase's period (owner, 18 Nov 2026). Lending joins in Phase 4.
class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({required this.onOpenAccounts, this.onAddAccount, this.clock = DateTime.now, super.key});

  final OpenAccounts onOpenAccounts;

  /// Passed on to Edit expense, for adding an account from it.
  final AddAccountAction? onAddAccount;
  final DateTime Function() clock;

  /// How many entries the tab lists before "Show all".
  static const listed = 10;
  static const listKey = ValueKey('money-list');

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

enum _Segment { expenses, lending }

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  late SpendingPeriod _period = SpendingPeriod.current(PeriodKind.month, widget.clock());

  /// The account, card or Cash in hand the tab is filtered to.
  String? _sourceId;

  /// The last report shown. Each period is its own query, so switching
  /// Day, Week or Month briefly has nothing loaded; showing this meanwhile
  /// keeps the screen from blanking (owner, 18 Nov 2026).
  SpendingReport? _shown;

  void _edit(SpendingEntry e) =>
      showExpenseSheet(context, expenseId: e.id, onAddAccount: widget.onAddAccount, clock: widget.clock);

  void _showAll(SpendingView view) =>
      showSpendingSheet(context, view: view, period: _period, sourceId: _sourceId, onEdit: _edit, clock: widget.clock);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = widget.clock();
    final reportAsync = ref.watch(spendingProvider(_period.start, _period.end));
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final banksAsync = ref.watch(accountsOfKindProvider(AccountKind.bank));
    final cardsAsync = ref.watch(accountsOfKindProvider(AccountKind.creditCard));
    if (reportAsync.hasValue) _shown = reportAsync.requireValue;
    final failed = [reportAsync, categoriesAsync, banksAsync, cardsAsync].any((a) => a.hasError);
    final ready = _shown != null && [categoriesAsync, banksAsync, cardsAsync].every((a) => a.hasValue);

    final body = <Widget>[];
    if (failed) {
      body.add(_padded(const LoopdErrorNote('Spending could not be loaded. Switch tabs and come back.')));
    } else if (ready) {
      final all = _shown!;
      final sources = SpendSource.all(banks: banksAsync.requireValue, cards: cardsAsync.requireValue, report: all);
      final source = sources.where((s) => s.id == _sourceId).firstOrNull;
      final report = source == null ? all : all.only(source.id);
      final categories = categoriesAsync.requireValue;
      final byCategory = report.byCategory;
      final suffix = source == null ? '' : ' · ${source.name}';
      body.addAll([
        _padded(
          _TotalCard(label: _period.spentLabel(now) + (source == null ? '' : ' from ${source.name}'), report: report),
        ),
        const SizedBox(height: 22),
        _padded(
          _SectionTitle(
            'Spent from',
            trailing: source == null
                ? null
                : _SmallButton(label: 'Show all', onTap: () => setState(() => _sourceId = null)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.gutter, vertical: 6),
            children: [
              for (final (i, s) in sources.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                SpendSourceChip(
                  source: s,
                  paise: all.byAccount[s.id] ?? 0,
                  selected: s.id == _sourceId,
                  dimmed: _sourceId != null && s.id != _sourceId,
                  onTap: () => setState(() => _sourceId = s.id == _sourceId ? null : s.id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (report.entries.isEmpty)
          _padded(_Empty(text: source == null ? 'Nothing spent in this period.' : 'Nothing spent from ${source.name}.'))
        else ...[
          if (byCategory.isNotEmpty) ...[
            _padded(_SectionTitle('Categories$suffix')),
            const SizedBox(height: 10),
            _padded(
              SpendingBox(
                children: [
                  for (final (id, paise) in byCategory.take(5))
                    CategoryShareRow(
                      category: categoryLook(id, categories),
                      paise: paise,
                      totalPaise: report.totalPaise,
                      largestPaise: byCategory.first.$2,
                    ),
                ],
              ),
            ),
            if (byCategory.length > 5) ...[
              const SizedBox(height: 10),
              _padded(
                _OutlineButton(label: 'Show all ${byCategory.length}', onTap: () => _showAll(SpendingView.categories)),
              ),
            ],
            const SizedBox(height: 22),
          ],
          _padded(
            _SectionTitle(
              'Expenses$suffix',
              trailing: Text(
                report.entries.length == 1 ? '1 entry' : '${report.entries.length} entries',
                style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _padded(
            SpendingList(
              key: MoneyScreen.listKey,
              entries: report.entries.take(MoneyScreen.listed).toList(),
              categories: categories,
              now: now,
              onEdit: _edit,
            ),
          ),
          if (report.entries.length > MoneyScreen.listed) ...[
            const SizedBox(height: 10),
            _padded(
              _OutlineButton(label: 'Show all ${report.entries.length}', onTap: () => _showAll(SpendingView.expenses)),
            ),
          ],
        ],
      ]);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Room at the bottom for the capture button.
          padding: const EdgeInsets.fromLTRB(0, 28, 0, 120),
          children: [
            _padded(
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      container: true,
                      header: true,
                      child: Text('Money', style: LoopdType.display.copyWith(color: c.textPrimary)),
                    ),
                  ),
                  Semantics(
                    container: true,
                    child: LoopdRoundButton(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Accounts and cards',
                      background: c.surfaceRaised,
                      foreground: c.textPrimary,
                      onTap: () => widget.onOpenAccounts(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _padded(
              LoopdSegmented<_Segment>(
                segments: [
                  LoopdSegment(value: _Segment.expenses, label: 'Expenses', color: c.money),
                  LoopdSegment(value: _Segment.lending, label: 'Lending', color: c.lending),
                ],
                selected: _Segment.expenses,
                onChanged: (segment) {
                  if (segment == _Segment.lending) showLoopdToast(context, 'Lending is built in Phase 4');
                },
              ),
            ),
            const SizedBox(height: 18),
            _padded(_PeriodPicker(period: _period, now: now, onChanged: (period) => setState(() => _period = period))),
            const SizedBox(height: 18),
            ...body,
          ],
        ),
      ),
    );
  }
}

Widget _padded(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.gutter),
  child: child,
);

/// Day, Week or Month, then ‹ the period's name ›. There is nothing after
/// the current period, so › is faded there.
class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.period, required this.now, required this.onChanged});

  final SpendingPeriod period;
  final DateTime now;
  final ValueChanged<SpendingPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    final latest = period.holds(now) || period.next.start.isAfter(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final kind in PeriodKind.values) ...[
              if (kind != PeriodKind.day) const SizedBox(width: LoopdSpace.sm),
              LoopdPressable(
                onTap: () => onChanged(SpendingPeriod.current(kind, now)),
                selected: kind == period.kind,
                label: _kindLabel(kind),
                child: AnimatedContainer(
                  duration: motion.quick,
                  height: LoopdSize.minTouch,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg),
                  decoration: BoxDecoration(
                    color: kind == period.kind ? c.money : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(LoopdRadius.pill),
                    border: Border.all(color: kind == period.kind ? c.money : c.line),
                  ),
                  child: Text(
                    _kindLabel(kind),
                    style: LoopdType.small.copyWith(color: kind == period.kind ? c.onAccent : c.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: LoopdSpace.md),
        Row(
          children: [
            LoopdRoundButton(
              icon: Icons.chevron_left_rounded,
              iconSize: 22,
              label: 'Earlier',
              background: c.surfaceRaised,
              foreground: c.textPrimary,
              onTap: () => onChanged(period.previous),
            ),
            Expanded(
              child: Text(
                period.title(),
                textAlign: TextAlign.center,
                style: LoopdType.heading.copyWith(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Opacity(
              opacity: latest ? 0.45 : 1,
              child: LoopdRoundButton(
                icon: Icons.chevron_right_rounded,
                iconSize: 22,
                label: 'Later',
                background: c.surfaceRaised,
                foreground: latest ? c.textMuted : c.textPrimary,
                onTap: latest ? null : () => onChanged(period.next),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _kindLabel(PeriodKind kind) => switch (kind) {
    PeriodKind.day => 'Day',
    PeriodKind.week => 'Week',
    PeriodKind.month => 'Month',
  };
}

/// The total, then the UPI, Credit Card and Cash bar with each amount. A
/// method with nothing spent is left out of both (owner, 18 Nov 2026).
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.report});

  final String label;
  final SpendingReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final methods = report.byMethod;
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
      padding: const EdgeInsets.all(LoopdSpace.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: LoopdType.small.copyWith(color: c.money)),
          const SizedBox(height: LoopdSpace.xxs),
          Semantics(
            container: true,
            label: '$label, ${formatRupees(report.totalPaise)}',
            excludeSemantics: true,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                formatRupees(report.totalPaise),
                style: LoopdType.amountLarge.copyWith(color: c.textPrimary, fontSize: 44, letterSpacing: -1),
              ),
            ),
          ),
          if (methods.isNotEmpty) ...[
            const SizedBox(height: 14),
            Semantics(
              container: true,
              label: methods.map((m) => '${name(m.$1)} ${formatRupees(m.$2)}').join(', '),
              excludeSemantics: true,
              child: Row(
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
            ),
            const SizedBox(height: 14),
            ExcludeSemantics(
              child: Wrap(
                spacing: 28,
                runSpacing: LoopdSpace.sm,
                children: [
                  for (final (method, paise) in methods)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: colour(method), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name(method),
                              style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: LoopdSpace.xxs),
                        Text(formatRupees(paise), style: LoopdType.amount.copyWith(color: c.textPrimary, fontSize: 16)),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          container: true,
          header: true,
          child: Text(text, style: LoopdType.small.copyWith(color: context.colors.textMuted)),
        ),
      ),
      ?trailing,
    ],
  );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      child: LoopdPressable(
        onTap: onTap,
        label: label,
        child: SizedBox(
          height: LoopdSize.minTouch,
          child: Center(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(LoopdRadius.pill)),
              child: Text(label, style: LoopdType.caption.copyWith(color: c.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LoopdPressable(
      onTap: onTap,
      label: label,
      child: Container(
        height: LoopdSize.minTouch,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LoopdRadius.pill),
          border: Border.all(color: c.line),
        ),
        child: Text(label, style: LoopdType.small.copyWith(color: c.textPrimary)),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: LoopdSpace.xxl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
        border: Border.all(color: c.line),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: LoopdType.body.copyWith(color: c.textSecondary),
      ),
    );
  }
}
