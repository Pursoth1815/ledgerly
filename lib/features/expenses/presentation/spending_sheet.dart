import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ledger/ledger_types.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import '../../accounts/accounts.dart';
import 'providers/expense_providers.dart';
import 'spending_parts.dart';
import 'spending_period.dart';

/// What the Show all sheet lists.
enum SpendingView { categories, expenses }

/// Opens Show all (mockup `MoneyAll.dc.html`, screens 5b and 5c): every
/// category, or every expense, of the Money tab's period, for the chosen
/// account or card ([sourceId]) or for them all. One tall sheet with two
/// views; no close button, as on the category sheet.
Future<void> showSpendingSheet(
  BuildContext context, {
  required SpendingView view,
  required SpendingPeriod period,
  required ValueChanged<SpendingEntry> onEdit,
  String? sourceId,
  DateTime Function() clock = DateTime.now,
}) => showLoopdSheet<void>(
  context: context,
  tall: true,
  builder: (_) => SpendingSheet(view: view, period: period, sourceId: sourceId, onEdit: onEdit, clock: clock),
);

class SpendingSheet extends ConsumerWidget {
  const SpendingSheet({
    required this.view,
    required this.period,
    required this.onEdit,
    this.sourceId,
    this.clock = DateTime.now,
    super.key,
  });

  final SpendingView view;
  final SpendingPeriod period;
  final String? sourceId;
  final ValueChanged<SpendingEntry> onEdit;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = clock();
    final reportAsync = ref.watch(spendingProvider(period.start, period.end));
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final banksAsync = ref.watch(accountsOfKindProvider(AccountKind.bank));
    final cardsAsync = ref.watch(accountsOfKindProvider(AccountKind.creditCard));
    final all = [reportAsync, categoriesAsync, banksAsync, cardsAsync];
    final title = view == SpendingView.categories ? 'Categories' : 'Expenses';

    Widget body;
    String subtitle = period.title();
    if (all.any((a) => a.hasError)) {
      body = const Align(
        alignment: Alignment.topCenter,
        child: LoopdErrorNote('This could not be loaded. Close it and try again.'),
      );
    } else if (!all.every((a) => a.hasValue)) {
      body = const SizedBox.expand();
    } else {
      final everything = reportAsync.requireValue;
      final sources = SpendSource.all(
        banks: banksAsync.requireValue,
        cards: cardsAsync.requireValue,
        report: everything,
      );
      final source = sources.where((s) => s.id == sourceId).firstOrNull;
      final report = source == null ? everything : everything.only(source.id);
      final categories = categoriesAsync.requireValue;
      final byCategory = report.byCategory;
      final count = view == SpendingView.categories ? byCategory.length : report.entries.length;
      final noun = view == SpendingView.categories
          ? (count == 1 ? 'category' : 'categories')
          : (count == 1 ? 'entry' : 'entries');
      subtitle = '${period.title()} · $count $noun';
      body = ListView(
        padding: EdgeInsets.zero,
        children: [
          SpendSourceCard(source: source, paise: report.totalPaise, caption: period.spentLabel(now)),
          const SizedBox(height: LoopdSpace.lg),
          if (view == SpendingView.categories)
            SpendingBox(
              children: [
                for (final (id, paise) in byCategory)
                  CategoryShareRow(
                    category: categoryLook(id, categories),
                    paise: paise,
                    totalPaise: report.totalPaise,
                    largestPaise: byCategory.first.$2,
                  ),
              ],
            )
          else
            SpendingList(entries: report.entries, categories: categories, now: now, onEdit: onEdit),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: LoopdType.title.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LoopdSpace.xxs),
        Text(
          subtitle,
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Expanded(child: body),
      ],
    );
  }
}
