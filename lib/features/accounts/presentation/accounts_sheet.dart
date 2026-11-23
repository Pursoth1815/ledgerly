import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_dashed_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'account_details_sheet.dart';
import 'add_account_sheet.dart';
import 'providers/accounts_providers.dart';
import 'short_dates.dart';
import 'wallet_card.dart';
import 'wallet_detail.dart';

/// Opens one account's expenses for this month. `app/` passes it in, because
/// that list belongs to Expenses (architecture rule 3).
typedef ViewAccountExpenses = Future<void> Function(BuildContext context, String accountId);

/// Opens Accounts and cards as a tall sheet over the whole app, tab bar
/// included (owner, 18 Nov 2026: a sheet, not a page).
Future<void> showAccountsSheet(
  BuildContext context, {
  ViewAccountExpenses? onViewExpenses,
  DateTime Function() clock = DateTime.now,
}) => showLoopdSheet<void>(
  context: context,
  tall: true,
  builder: (_) => AccountsSheet(onViewExpenses: onViewExpenses, clock: clock),
);

/// The wallet (mockup `Wallet.dc.html`, screens A1 to A4). Loopd records
/// spending only (owner, 23 Nov 2026), so each card shows what it spent this
/// month. Tapping one moves it to the top while the others slide down and
/// fade, then its details rise in. Back plays the same motion in reverse.
class AccountsSheet extends ConsumerStatefulWidget {
  const AccountsSheet({this.onViewExpenses, this.clock = DateTime.now, super.key});

  final ViewAccountExpenses? onViewExpenses;

  /// The current time; replaced in tests.
  final DateTime Function() clock;

  /// Finds the loaded wallet in tests.
  static const listKey = ValueKey('accounts-list');

  @override
  ConsumerState<AccountsSheet> createState() => _AccountsSheetState();
}

class _AccountsSheetState extends ConsumerState<AccountsSheet> with TickerProviderStateMixin {
  static const _step = 76.0;
  static const _bannerHeight = 124.0;
  static const _barHeight = 44.0;
  static const _openTime = Duration(milliseconds: 1040);
  static const _closeTime = Duration(milliseconds: 900);
  static const _easeOut = Cubic(0.22, 0.8, 0.24, 1);

  /// 0 is the stack and 1 is one card open. Reversing it is the Back motion.
  late final _open = AnimationController(vsync: this, duration: _openTime, reverseDuration: _closeTime);

  /// The cards dealing in when the sheet opens.
  late final _deal = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  final _scroll = ScrollController();

  /// The opened card; kept while the Back motion plays.
  String? _openId;

  /// How far the stack was scrolled when the card was opened.
  double _openedAt = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _open.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) setState(() => _openId = null);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = LoopdMotion.of(context).reduced;
    _open
      ..duration = reduced ? Duration.zero : _openTime
      ..reverseDuration = reduced ? Duration.zero : _closeTime;
    if (!_started) {
      _started = true;
      if (reduced) {
        _deal.value = 1;
      } else {
        _deal.forward();
      }
    }
  }

  @override
  void dispose() {
    _open.dispose();
    _deal.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openCard(WalletItem item) {
    setState(() {
      _openId = item.id;
      _openedAt = _scroll.hasClients ? _scroll.offset : 0;
    });
    _open.forward();
  }

  void _close() => _open.reverse();

  Future<void> _add() async {
    final added = await showAddAccountSheet(context, kind: AccountKind.bank);
    if (added != null && mounted) showLoopdToast(context, 'Added $added');
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.clock();
    final month = DateTime(now.year, now.month);
    final reportAsync = ref.watch(walletSpendingProvider(month));
    final banksAsync = ref.watch(accountsOfKindProvider(AccountKind.bank));
    final cardsAsync = ref.watch(accountsOfKindProvider(AccountKind.creditCard));
    final all = [reportAsync, banksAsync, cardsAsync];
    if (all.any((a) => a.hasError)) {
      return const Align(
        alignment: Alignment.topCenter,
        child: LoopdErrorNote('Accounts could not be loaded. Close this and open it again.'),
      );
    }
    if (!all.every((a) => a.hasValue)) return const SizedBox.expand();

    final report = reportAsync.requireValue;
    final items = WalletItem.all(
      cards: cardsAsync.requireValue,
      banks: banksAsync.requireValue,
      month: report,
      now: now,
    );
    final opened = items.where((item) => item.id == _openId).firstOrNull;
    if (_openId != null && opened == null) {
      // The opened account was just removed: back to the stack.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _open.value = 0;
        setState(() => _openId = null);
      });
    }

    return PopScope(
      canPop: _openId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AnimatedBuilder(
        key: AccountsSheet.listKey,
        animation: Listenable.merge([_open, _deal]),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              progress: _open.value,
              deal: _deal.value,
              height: lerpDouble(
                _bannerHeight,
                _barHeight,
                const Interval(0, 0.42, curve: _easeOut).transform(_open.value),
              )!,
              totalPaise: report.totalPaise,
              now: now,
              title: opened == null ? '' : (opened.isCard ? 'Credit card' : (opened.isBank ? 'Bank account' : 'Cash')),
              onBack: _close,
            ),
            const SizedBox(height: LoopdSpace.lg),
            Expanded(child: _stage(items, opened, now)),
          ],
        ),
      ),
    );
  }

  Widget _stage(List<WalletItem> items, WalletItem? opened, DateTime now) {
    final c = context.colors;
    final progress = _open.value;
    final openIndex = opened == null ? -1 : items.indexOf(opened);
    final stackHeight = (items.length - 1) * _step + WalletCard.height;
    final addOpacity = 1 - const Interval(0, 0.3).transform(progress);
    return LayoutBuilder(
      builder: (context, constraints) {
        // While a card is open the content stays tall enough that the place
        // it was opened from cannot be scrolled away.
        final content = stackHeight + LoopdSpace.lg + LoopdSize.button + LoopdSpace.sm;
        final height = opened == null ? content : math.max(content, _openedAt + constraints.maxHeight);
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scroll,
                physics: opened == null ? null : const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height: height,
                  child: Stack(
                    children: [
                      for (final (i, item) in items.indexed) _card(item, i, items.length, openIndex),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: stackHeight + LoopdSpace.lg,
                        child: IgnorePointer(
                          ignoring: opened != null,
                          child: Opacity(
                            opacity: addOpacity * const Interval(0.55, 1).transform(_deal.value),
                            child: LoopdDashedButton(label: 'Add account or card', color: c.textSecondary, onTap: _add),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (opened != null)
              Positioned(
                left: 0,
                right: 0,
                top: WalletCard.height + 14,
                bottom: 0,
                child: WalletDetail(
                  item: opened,
                  progress: progress,
                  now: now,
                  onViewExpenses: widget.onViewExpenses == null
                      ? null
                      : () => widget.onViewExpenses!(context, opened.id),
                  onDetails: opened.account == null
                      ? null
                      : () => showAccountDetailsSheet(context, opened.account!, clock: widget.clock),
                ),
              ),
          ],
        );
      },
    );
  }

  /// One card's place in the motion. The cards keep their stack order, so
  /// each one settles back over the one above it.
  Widget _card(WalletItem item, int index, int count, int openIndex) {
    final progress = _open.value;
    final rest = index * _step;
    var top = rest;
    var opacity = 1.0;
    var scale = 1.0;
    if (openIndex == index) {
      top = lerpDouble(rest, _openedAt, const Interval(0.03, 0.62, curve: _easeOut).transform(progress))!;
    } else if (openIndex >= 0) {
      final wait = (index - openIndex).abs() * 0.03;
      final away = Interval(wait, math.min(wait + 0.5, 1), curve: _easeOut).transform(progress);
      top = rest + 190 * away;
      opacity = 1 - away;
      scale = 1 - 0.05 * away;
    }
    // Fully faded away: out of the tree, and so out of reach of a screen reader.
    if (opacity == 0) return const Positioned(left: 0, top: 0, width: 0, height: 0, child: SizedBox.shrink());
    final start = count <= 1 ? 0.0 : index / count * 0.42;
    final dealt = Interval(start, math.min(start + 0.58, 1), curve: _easeOut).transform(_deal.value);
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: WalletCard.height,
      child: IgnorePointer(
        ignoring: openIndex >= 0,
        child: ExcludeSemantics(
          excluding: openIndex >= 0 && openIndex != index,
          child: Opacity(
            opacity: opacity * dealt,
            child: Transform.translate(
              offset: Offset(0, 120 * (1 - dealt)),
              child: Transform.scale(
                scale: scale * (0.92 + 0.08 * dealt),
                alignment: Alignment.topCenter,
                child: WalletCard(
                  item: item,
                  overlaps: index > 0 && openIndex != index,
                  onTap: openIndex >= 0 ? null : () => _openCard(item),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The soft periwinkle banner over the stack, or the short bar with Back
/// while a card is open. They cross-fade with the wallet's motion.
class _Header extends StatelessWidget {
  const _Header({
    required this.progress,
    required this.deal,
    required this.height,
    required this.totalPaise,
    required this.now,
    required this.title,
    required this.onBack,
  });

  final double progress;
  final double deal;
  final double height;
  final int totalPaise;
  final DateTime now;
  final String title;
  final VoidCallback onBack;

  static const _background = Color(0xFFE3E6FF);
  static const _text = Color(0xFF1B1F4B);
  static const _soft = Color(0xFF4C5190);

  Widget _fanCard(double right, double top, double angle, Color colour, double wait, {bool chip = false}) {
    final value = Interval(wait, math.min(wait + 0.6, 1), curve: const Cubic(0.2, 0.85, 0.25, 1)).transform(deal);
    return Positioned(
      right: right,
      top: top,
      child: Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(-26 * (1 - value), 14 * (1 - value)),
          child: Transform.rotate(
            angle: angle * value * math.pi / 180,
            child: Container(
              width: 74,
              height: 48,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [BoxShadow(color: Color(0x240D0F14), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: chip
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8, top: 10),
                        width: 15,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCD34D),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bannerShown = 1 - const Interval(0, 0.27).transform(progress);
    final barShown = const Interval(0.15, 0.42).transform(progress);
    final amount = formatRupees(totalPaise);
    final month = longMonth(now);
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (bannerShown > 0)
            Positioned(
              left: 0,
              right: 0,
              top: -10 * (1 - bannerShown),
              height: _AccountsSheetState._bannerHeight,
              child: Opacity(
                opacity: bannerShown,
                child: Semantics(
                  container: true,
                  header: true,
                  label: 'Accounts and cards, $amount spent in $month',
                  excludeSemantics: true,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(24)),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accounts & cards',
                              style: LoopdType.label.copyWith(color: _text, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  amount,
                                  style: LoopdType.amountLarge.copyWith(
                                    color: _text,
                                    fontSize: 34,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                            ),
                            Text('spent in $month', style: LoopdType.small.copyWith(color: _soft)),
                          ],
                        ),
                        _fanCard(28, 10, -16, const Color(0xFFCDB8FF), 0.12),
                        _fanCard(12, 19, -4, const Color(0xFFFFD08F), 0.2),
                        _fanCard(-4, 32, 9, const Color(0xFFA5D8FF), 0.28, chip: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (barShown > 0)
            Positioned(
              left: 0,
              right: 0,
              top: 10 * (1 - barShown),
              height: _AccountsSheetState._barHeight,
              child: Opacity(
                opacity: barShown,
                child: Row(
                  children: [
                    Semantics(
                      container: true,
                      child: LoopdRoundButton(
                        icon: Icons.chevron_left_rounded,
                        iconSize: 24,
                        label: 'Back to all accounts and cards',
                        background: c.surfaceRaised,
                        foreground: c.textPrimary,
                        onTap: onBack,
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        container: true,
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: LoopdType.heading.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: LoopdSize.minTouch),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
