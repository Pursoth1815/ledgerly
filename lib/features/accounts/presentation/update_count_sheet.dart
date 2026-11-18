import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ledger/ledger_engine.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'providers/accounts_providers.dart';

/// Opens Update cash for Cash in hand (proposal section 4). Returns a short
/// message saying what was saved, or null when closed.
Future<String?> showUpdateCountSheet(BuildContext context) =>
    showLoopdSheet<String>(context: context, builder: (_) => const UpdateCountSheet());

/// You type what is really in your wallet, and that becomes Cash in hand. A
/// new count replaces the last one; the difference is not spending. Before
/// you save, the sheet shows what Loopd has now.
class UpdateCountSheet extends ConsumerStatefulWidget {
  const UpdateCountSheet({super.key});

  static const amountFieldKey = ValueKey('update-count-amount');

  @override
  ConsumerState<UpdateCountSheet> createState() => _UpdateCountSheetState();
}

class _UpdateCountSheetState extends ConsumerState<UpdateCountSheet> {
  final _amount = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(int paise) async {
    setState(() => _saving = true);
    await ref.read(ledgerEngineProvider).countCash(paise);
    if (mounted) Navigator.of(context).pop('Cash in hand is now ${formatRupees(paise)}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cash = ref.watch(cashInHandProvider).value;
    final typed = parseRupees(_amount.text);
    final String note;
    if (cash == null) {
      note = '';
    } else if (typed == null || typed == cash.balance.paise) {
      note = 'Loopd has ${formatRupees(cash.balance.paise)} now. Your count replaces it.';
    } else {
      final difference = typed - cash.balance.paise;
      note =
          '${formatRupees(difference.abs())} ${difference > 0 ? 'more' : 'less'} than Loopd has. '
          'Your count replaces it; the difference is not spending.';
    }
    final ready = cash != null && typed != null && !_saving;
    final big = LoopdType.amountLarge.copyWith(color: c.textPrimary);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Update cash', style: LoopdType.title.copyWith(color: c.textPrimary)),
                ),
              ),
              LoopdRoundButton(
                icon: Icons.close_rounded,
                label: 'Close',
                size: 40,
                background: c.surfaceRaised,
                foreground: c.textPrimary,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: LoopdSpace.xs),
          Text(
            'Count the cash in your wallet and type the total.',
            style: LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: LoopdSpace.xxl),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: LoopdSpace.lg),
            decoration: BoxDecoration(
              color: c.cashTint,
              borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
              border: Border.all(color: c.cash, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('₹', style: big.copyWith(color: c.cash)),
                const SizedBox(width: LoopdSpace.xs),
                IntrinsicWidth(
                  child: TextField(
                    key: UpdateCountSheet.amountFieldKey,
                    controller: _amount,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    style: big,
                    cursorColor: c.cash,
                    decoration: InputDecoration.collapsed(
                      hintText: '0',
                      hintStyle: big.copyWith(color: c.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LoopdSpace.md),
          Text(
            note,
            textAlign: TextAlign.center,
            style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: LoopdSpace.xl),
          LoopdButton(label: 'Save', onTap: ready ? () => _save(typed) : null),
        ],
      ),
    );
  }
}
