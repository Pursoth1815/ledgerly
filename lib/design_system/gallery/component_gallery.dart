import 'package:flutter/material.dart';

import '../components/loopd_button.dart';
import '../components/loopd_card.dart';
import '../components/loopd_card_stack.dart';
import '../components/loopd_check.dart';
import '../components/loopd_chip.dart';
import '../components/loopd_error_note.dart';
import '../components/loopd_sheet.dart';
import '../components/loopd_source_strip.dart';
import '../components/loopd_switch.dart';
import '../loopd_colors.dart';
import '../loopd_spacing.dart';
import '../loopd_theme.dart';
import '../loopd_typography.dart';

/// Every shared component on one page, to check them on the phone in both
/// themes (Phase 1). Opened from More in debug and profile builds only; the
/// release app does not contain the route. All data is made up.
class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  Brightness? _brightness;
  bool _sms = true;
  bool _reminders = false;
  bool _dark = true;
  final _tasks = <String, bool>{'Pay electricity bill': false, 'Call the bank': true, 'Renew passport': false};
  String _category = 'Travel';

  @override
  Widget build(BuildContext context) {
    final brightness = _brightness ?? Theme.of(context).brightness;
    return Theme(
      data: loopdTheme(brightness),
      child: Builder(builder: (context) => _page(context, brightness)),
    );
  }

  Widget _page(BuildContext context, Brightness brightness) {
    final c = context.colors;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: LoopdSpace.xxl, bottom: LoopdSpace.md),
      child: Text(text, style: LoopdType.heading.copyWith(color: c.textPrimary)),
    );
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(LoopdSpace.gutter, LoopdSpace.lg, LoopdSpace.gutter, 40),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Components', style: LoopdType.pageTitle.copyWith(color: c.textPrimary)),
                ),
                LoopdSwitch(
                  label: 'Show dark',
                  value: brightness == Brightness.dark,
                  activeColor: c.themeSwitch,
                  onChanged: (dark) => setState(() => _brightness = dark ? Brightness.dark : Brightness.light),
                ),
              ],
            ),
            Text('All names and amounts are made up', style: LoopdType.caption.copyWith(color: c.textMuted)),

            heading('Type'),
            Text('Today', style: LoopdType.display.copyWith(color: c.textPrimary)),
            Text('Accounts and cards', style: LoopdType.pageTitle.copyWith(color: c.textPrimary)),
            Text('₹705.00', style: LoopdType.amountLarge.copyWith(color: c.textPrimary)),
            Text('New task', style: LoopdType.title.copyWith(color: c.textPrimary)),
            Text('Waiting for confirmation', style: LoopdType.heading.copyWith(color: c.textPrimary)),
            Text('Body text in Plus Jakarta Sans', style: LoopdType.body.copyWith(color: c.textSecondary)),
            Text('Detected from SMS · 14 Nov, 10:39 am', style: LoopdType.caption.copyWith(color: c.textMuted)),
            Text('PNR 482-1937560', style: LoopdType.code.copyWith(color: c.travel)),

            heading('Colours'),
            Wrap(
              spacing: LoopdSpace.sm,
              runSpacing: LoopdSpace.sm,
              children: [
                for (final (name, color, tint) in [
                  ('UPI', c.money, c.moneyTint),
                  ('Card', c.creditCard, c.creditCardTint),
                  ('Cash', c.cash, c.cashTint),
                  ('Lending', c.lending, c.lendingTint),
                  ('Travel', c.travel, c.travelTint),
                  ('Notes', c.notes, c.notesTint),
                  ('Vault', c.vault, c.vaultTint),
                  ('Wellbeing', c.wellbeing, c.wellbeingTint),
                  ('Overdue', c.danger, c.dangerTint),
                  ('Review', c.review, c.reviewTint),
                ])
                  LoopdBadge(label: name, color: color, tint: tint),
              ],
            ),

            heading('Review stack'),
            LoopdCardStack(
              behind: 2,
              openLabel: 'Open Review Inbox, 2 more waiting',
              onOpen: () => _toast(context, 'Opens the Review Inbox'),
              top: LoopdCard(
                semanticLabel: 'New transaction detected, 705 rupees',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(color: Color(0xFF60A5FA), shape: BoxShape.circle),
                          child: const Icon(Icons.directions_bus_outlined, size: 20, color: Color(0xFF0D0F14)),
                        ),
                        const SizedBox(width: LoopdSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'State Transport Co',
                                style: LoopdType.bodyStrong.copyWith(color: c.textPrimary, fontSize: 16),
                              ),
                              Text(
                                'Detected from SMS · 14 Nov, 10:39 am',
                                style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: LoopdSpace.lg),
                    Text('₹705.00', style: LoopdType.amountLarge.copyWith(color: c.textPrimary)),
                    const SizedBox(height: LoopdSpace.lg),
                    LoopdSourceStrip(
                      leading: const LoopdMiniCard(color: Color(0xFF1D4ED8), lastFour: '4417'),
                      title: 'Kiwi · Sample Bank',
                      subtitle: 'Credit card ••4417 · paid by UPI QR',
                      trailing: LoopdBadge(label: 'CC', color: c.creditCard, tint: c.creditCardTint),
                    ),
                    const SizedBox(height: LoopdSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Category',
                            style: LoopdType.small.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const LoopdChip(label: 'Travel', dotColor: Color(0xFF60A5FA)),
                      ],
                    ),
                    const SizedBox(height: LoopdSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: LoopdButton(
                            label: 'Review',
                            style: LoopdButtonStyle.outlined,
                            onTap: () => _toast(context, 'Review'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LoopdButton(
                            label: 'Looks Good',
                            trailingIcon: Icons.check_rounded,
                            onTap: () => _toast(context, 'Looks Good'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            heading('Payment sources'),
            Text(
              'Used inside the review card on Today and in the Review Inbox, one per method.',
              style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: LoopdSpace.sm),
            LoopdCard(
              child: Column(
                children: [
                  LoopdSourceStrip(
                    leading: const LoopdMiniCard(color: Color(0xFF1D4ED8), lastFour: '4417'),
                    title: 'Kiwi · Sample Bank',
                    subtitle: 'Credit card ••4417 · paid by UPI QR',
                    trailing: LoopdBadge(label: 'CC', color: c.creditCard, tint: c.creditCardTint),
                  ),
                  const SizedBox(height: 10),
                  LoopdSourceStrip(
                    leading: const LoopdMiniCard(color: Color(0xFF0F766E), lastFour: '0042'),
                    title: 'Daily · Sample Bank',
                    subtitle: 'Savings ••0042 · UPI',
                    trailing: LoopdBadge(label: 'UPI', color: c.money, tint: c.moneyTint),
                  ),
                  const SizedBox(height: 10),
                  LoopdSourceStrip(
                    leading: Container(
                      width: 46,
                      height: 30,
                      decoration: BoxDecoration(color: c.cashTint, borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.payments_outlined, size: 18, color: c.cash),
                    ),
                    title: 'Cash in hand',
                    subtitle: '₹2,340 left after this',
                    trailing: LoopdBadge(label: 'Cash', color: c.cash, tint: c.cashTint),
                  ),
                ],
              ),
            ),

            heading('Chips'),
            Wrap(
              spacing: LoopdSpace.sm,
              children: [
                for (final (name, dot) in [
                  ('Travel', const Color(0xFF60A5FA)),
                  ('Food', const Color(0xFFFF8A4C)),
                  ('Shopping', const Color(0xFFF472B6)),
                ])
                  LoopdChip(
                    label: name,
                    dotColor: dot,
                    selected: _category == name,
                    onTap: () => setState(() => _category = name),
                  ),
              ],
            ),

            heading('Tasks'),
            LoopdCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: LoopdSpace.sm),
              child: Column(
                children: [
                  for (final entry in _tasks.entries)
                    Row(
                      children: [
                        Transform.translate(
                          offset: const Offset(-12, 0),
                          child: LoopdCheck(
                            label: entry.key,
                            done: entry.value,
                            overdue: entry.key == 'Renew passport',
                            onChanged: (done) => setState(() => _tasks[entry.key] = done),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: LoopdType.body.copyWith(
                              color: entry.value ? c.textMuted : c.textPrimary,
                              decoration: entry.value ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            heading('Switches'),
            LoopdCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: LoopdSpace.xs),
              child: Column(
                children: [
                  _switchRow(context, 'SMS detection', _sms, c.review, (v) => setState(() => _sms = v)),
                  _switchRow(context, 'Task reminders', _reminders, c.notes, (v) => setState(() => _reminders = v)),
                  _switchRow(context, 'Dark theme', _dark, c.themeSwitch, (v) => setState(() => _dark = v)),
                ],
              ),
            ),

            heading('Error note'),
            const LoopdErrorNote('Primary already ends ••2210. Each bank account needs its own last four digits.'),

            heading('Buttons'),
            LoopdButton(label: 'Save', onTap: () => _toast(context, 'Save')),
            const SizedBox(height: 10),
            LoopdButton(
              label: 'Back up now',
              icon: Icons.cloud_upload_outlined,
              style: LoopdButtonStyle.solid,
              onTap: () => _toast(context, 'Back up now'),
            ),

            const SizedBox(height: 10),
            const LoopdButton(label: 'Save (disabled)', onTap: null),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(
                  child: LoopdButton(
                    label: 'Back up now',
                    icon: Icons.cloud_upload_outlined,
                    style: LoopdButtonStyle.solid,
                    onTap: null,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: LoopdButton(label: 'Review', style: LoopdButtonStyle.outlined, onTap: null),
                ),
              ],
            ),

            heading('Sheet'),
            LoopdButton(
              label: 'Open a sheet',
              style: LoopdButtonStyle.outlined,
              onTap: () => showLoopdSheet<void>(
                context: context,
                title: 'New task',
                builder: (sheetContext) => Text(
                  'Sheets open from the bottom with one handle and 30 px corners.',
                  style: LoopdType.body.copyWith(color: c.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(BuildContext context, String label, bool value, Color color, ValueChanged<bool> onChanged) => Row(
    children: [
      Expanded(
        child: Text(label, style: LoopdType.body.copyWith(color: context.colors.textPrimary)),
      ),
      LoopdSwitch(label: label, value: value, activeColor: color, onChanged: onChanged),
    ],
  );

  void _toast(BuildContext context, String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
}
