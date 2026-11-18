import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ledger/ledger_engine.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_source_strip.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'account_look.dart';

/// Opens the options for one bank account or card: Make default and Remove
/// (proposal section 4). Shows a toast with what was done.
Future<void> showAccountOptionsSheet(BuildContext context, LedgerAccount account) async {
  final message = await showLoopdSheet<String>(
    context: context,
    builder: (_) => AccountOptionsSheet(account: account),
  );
  if (message != null && context.mounted) showLoopdToast(context, message);
}

/// Removing asks once more, because it cannot be undone from here. Past
/// transactions stay, under the name they were saved with.
class AccountOptionsSheet extends ConsumerStatefulWidget {
  const AccountOptionsSheet({required this.account, super.key});

  final LedgerAccount account;

  @override
  ConsumerState<AccountOptionsSheet> createState() => _AccountOptionsSheetState();
}

class _AccountOptionsSheetState extends ConsumerState<AccountOptionsSheet> {
  bool _confirmRemove = false;

  LedgerAccount get _account => widget.account;
  bool get _isCard => _account.kind == AccountKind.creditCard;

  Future<void> _makeDefault() async {
    await ref.read(ledgerEngineProvider).setDefault(_account.id);
    if (mounted) {
      Navigator.of(context).pop('${_account.nickname} is now the default ${_isCard ? 'card' : 'for UPI'}');
    }
  }

  Future<void> _remove() async {
    await ref.read(ledgerEngineProvider).removeAccount(_account.id);
    if (mounted) Navigator.of(context).pop('Removed ${_account.nickname}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final code = _account.bankCode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            LoopdMiniCard(color: bankColour(_account.bankName, c)),
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      _account.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LoopdType.title.copyWith(color: c.textPrimary),
                    ),
                  ),
                  Text(
                    _account.bankAndDigits,
                    style: LoopdType.small.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
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
        const SizedBox(height: LoopdSpace.lg),
        Text(
          code == null
              ? 'Not in the bank list, so SMS from this bank are not linked yet.'
              : 'SMS from $code ending ${_account.last4} are linked here.',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.xl),
        if (!_confirmRemove) ...[
          if (!_account.isDefault) ...[
            LoopdButton(
              label: _isCard ? 'Make default card' : 'Make default for UPI',
              style: LoopdButtonStyle.outlined,
              onTap: _makeDefault,
            ),
            const SizedBox(height: LoopdSpace.md),
          ],
          LoopdButton(
            label: 'Remove',
            icon: Icons.delete_outline_rounded,
            accent: c.danger,
            onTap: () => setState(() => _confirmRemove = true),
          ),
        ] else ...[
          Text('Remove ${_account.nickname}?', style: LoopdType.heading.copyWith(color: c.textPrimary)),
          const SizedBox(height: LoopdSpace.xs),
          Text(
            'Its past expenses stay, under this name. New expenses and SMS can no longer use it.',
            style: LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: LoopdSpace.lg),
          Row(
            children: [
              Expanded(
                child: LoopdButton(
                  label: 'Keep',
                  style: LoopdButtonStyle.outlined,
                  onTap: () => setState(() => _confirmRemove = false),
                ),
              ),
              const SizedBox(width: LoopdSpace.md),
              Expanded(
                child: LoopdButton(label: 'Remove', accent: c.danger, onTap: _remove),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
