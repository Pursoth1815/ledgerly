@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/design_system/components/loopd_button.dart';
import 'package:loopd/design_system/components/loopd_card.dart';
import 'package:loopd/design_system/components/loopd_card_stack.dart';
import 'package:loopd/design_system/components/loopd_check.dart';
import 'package:loopd/design_system/components/loopd_chip.dart';
import 'package:loopd/design_system/components/loopd_error_note.dart';
import 'package:loopd/design_system/components/loopd_source_strip.dart';
import 'package:loopd/design_system/components/loopd_switch.dart';
import 'package:loopd/design_system/loopd_colors.dart';
import 'package:loopd/design_system/loopd_spacing.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/design_system/loopd_typography.dart';

import '../../support/golden_fonts.dart';

/// Visual tests (Phase 1): the components drawn with the real fonts in both
/// themes, compared with saved pictures in `goldens/`.
///
/// Text drawing differs slightly between macOS and Linux, so these run on the
/// Mac, not in CI: `flutter test --tags golden`. After an intended change,
/// refresh them with `flutter test --tags golden --update-goldens` and look at
/// the new pictures before committing.
Widget _sample(Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: loopdTheme(brightness),
  home: Builder(
    builder: (context) {
      final c = context.colors;
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(LoopdSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Today', style: LoopdType.display.copyWith(color: c.textPrimary)),
              const SizedBox(height: LoopdSpace.md),
              LoopdCardStack(
                behind: 2,
                top: LoopdCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sample Transport Co', style: LoopdType.bodyStrong.copyWith(color: c.textPrimary)),
                      Text('₹705.00', style: LoopdType.amountLarge.copyWith(color: c.textPrimary)),
                      const SizedBox(height: LoopdSpace.md),
                      LoopdSourceStrip(
                        leading: const LoopdMiniCard(color: Color(0xFF1D4ED8), lastFour: '1234'),
                        title: 'Kiwi · Sample Bank',
                        subtitle: 'Credit card ••1234 · paid by UPI QR',
                        trailing: LoopdBadge(label: 'CC', color: c.creditCard, tint: c.creditCardTint),
                      ),
                      const SizedBox(height: LoopdSpace.md),
                      Row(
                        children: [
                          Expanded(
                            child: LoopdButton(label: 'Review', style: LoopdButtonStyle.outlined, onTap: () {}),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LoopdButton(label: 'Looks Good', onTap: () {}),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LoopdSpace.lg),
              Wrap(
                spacing: LoopdSpace.sm,
                children: [
                  LoopdChip(label: 'Travel', dotColor: const Color(0xFF60A5FA), selected: true, onTap: () {}),
                  LoopdChip(label: 'Food', dotColor: const Color(0xFFFF8A4C), onTap: () {}),
                  LoopdBadge(label: '5 New', color: c.review, tint: c.reviewTint),
                ],
              ),
              Row(
                children: [
                  LoopdCheck(label: 'done', done: true, onChanged: (_) {}),
                  LoopdCheck(label: 'open', done: false, onChanged: (_) {}),
                  LoopdCheck(label: 'overdue', done: false, overdue: true, onChanged: (_) {}),
                  const Spacer(),
                  LoopdSwitch(label: 'off', value: false, onChanged: (_) {}),
                  const SizedBox(width: LoopdSpace.sm),
                  LoopdSwitch(label: 'on', value: true, activeColor: c.themeSwitch, onChanged: (_) {}),
                ],
              ),
              Text('PNR 482-1937560', style: LoopdType.code.copyWith(color: c.travel)),
              const SizedBox(height: LoopdSpace.sm),
              const LoopdErrorNote('Primary already ends ••2210.'),
              const SizedBox(height: LoopdSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: LoopdButton(
                      label: 'Back up now',
                      icon: Icons.cloud_upload_outlined,
                      style: LoopdButtonStyle.solid,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: LoopdButton(label: 'Disabled', onTap: null)),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ),
);

void main() {
  setUpAll(loadGoldenFonts);

  for (final brightness in Brightness.values) {
    testWidgets('components in ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(1080, 1680);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_sample(brightness));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/components_${brightness.name}.png'));
    });
  }
}
