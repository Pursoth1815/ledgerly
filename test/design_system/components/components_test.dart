import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/design_system/components/loopd_button.dart';
import 'package:loopd/design_system/components/loopd_card.dart';
import 'package:loopd/design_system/components/loopd_card_stack.dart';
import 'package:loopd/design_system/components/loopd_check.dart';
import 'package:loopd/design_system/components/loopd_chip.dart';
import 'package:loopd/design_system/components/loopd_error_note.dart';
import 'package:loopd/design_system/components/loopd_pressable.dart';
import 'package:loopd/design_system/components/loopd_sheet.dart';
import 'package:loopd/design_system/components/loopd_switch.dart';
import 'package:loopd/design_system/loopd_colors.dart';
import 'package:loopd/design_system/loopd_spacing.dart';

import '../../support/loopd_test_app.dart';

void main() {
  group('LoopdSwitch', () {
    testWidgets('toggles, is labelled for screen readers and takes its colour when on', (tester) async {
      var value = false;
      await tester.pumpWidget(
        loopdTestApp(
          StatefulBuilder(
            builder: (context, setState) => LoopdSwitch(
              label: 'Dark theme',
              value: value,
              activeColor: context.colors.themeSwitch,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(LoopdSwitch)),
        matchesSemantics(
          label: 'Dark theme',
          hasToggledState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byType(LoopdSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      final track = tester.widget<AnimatedContainer>(
        find.descendant(of: find.byType(LoopdSwitch), matching: find.byType(AnimatedContainer)),
      );
      expect((track.decoration! as BoxDecoration).color, LoopdColors.dark.themeSwitch);
    });

    testWidgets('has a 44 px tall touch area', (tester) async {
      await tester.pumpWidget(loopdTestApp(LoopdSwitch(label: 'SMS', value: true, onChanged: (_) {})));
      expect(tester.getSize(find.byType(LoopdSwitch)).height, greaterThanOrEqualTo(LoopdSize.minTouch));
    });
  });

  group('LoopdCheck', () {
    testWidgets('ticks a task and reports it as checked', (tester) async {
      var done = false;
      await tester.pumpWidget(
        loopdTestApp(
          StatefulBuilder(
            builder: (context, setState) =>
                LoopdCheck(label: 'Call the bank', done: done, onChanged: (v) => setState(() => done = v)),
          ),
        ),
      );
      await tester.tap(find.byType(LoopdCheck));
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(
        tester.getSemantics(find.byType(LoopdCheck)),
        matchesSemantics(
          label: 'Call the bank',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(tester.getSize(find.byType(LoopdCheck)), const Size.square(LoopdSize.minTouch));
    });

    testWidgets('settles at once when the phone asks to reduce motion', (tester) async {
      await tester.pumpWidget(
        loopdTestApp(LoopdCheck(label: 'Task', done: false, onChanged: (_) {}), reduceMotion: true),
      );
      await tester.pumpWidget(
        loopdTestApp(LoopdCheck(label: 'Task', done: true, onChanged: (_) {}), reduceMotion: true),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('a chip reports its selection and grows to a 44 px touch area', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      loopdTestApp(LoopdChip(label: 'Travel', dotColor: Colors.blue, selected: true, onTap: () => taps++)),
    );
    await tester.tap(find.text('Travel'));
    expect(taps, 1);
    expect(tester.getSize(find.byType(LoopdChip)).height, greaterThanOrEqualTo(LoopdSize.minTouch));
    expect(
      tester.getSemantics(find.byType(LoopdPressable)),
      matchesSemantics(
        label: 'Travel',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('a disabled button does nothing', (tester) async {
    await tester.pumpWidget(loopdTestApp(const SizedBox(width: 300, child: LoopdButton(label: 'Save', onTap: null))));
    await tester.tap(find.text('Save'), warnIfMissed: false);
    expect(
      tester.getSemantics(find.byType(LoopdPressable)),
      matchesSemantics(label: 'Save', isButton: true, hasEnabledState: true),
    );
  });

  testWidgets('the stack shows two edges for cards waiting behind, and opens the list', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      loopdTestApp(
        SizedBox(
          width: 360,
          child: LoopdCardStack(
            behind: 4,
            openLabel: 'Open Review Inbox, 4 more waiting',
            onOpen: () => opened = true,
            top: const LoopdCard(child: SizedBox(height: 80)),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Open Review Inbox, 4 more waiting'), findsOneWidget);
    await tester.tapAt(tester.getBottomLeft(find.byType(LoopdCardStack)) + const Offset(180, -2));
    expect(opened, isTrue);
  });

  testWidgets('a stack with nothing behind is just the card', (tester) async {
    await tester.pumpWidget(loopdTestApp(const LoopdCardStack(behind: 0, top: Text('only'))));
    expect(find.descendant(of: find.byType(LoopdCardStack), matching: find.byType(Stack)), findsNothing);
  });

  testWidgets('a sheet opens with one handle and its title', (tester) async {
    await tester.pumpWidget(
      loopdTestApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showLoopdSheet<void>(context: context, title: 'New task', builder: (_) => const Text('body')),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
    expect(find.byKey(LoopdSheet.handleKey), findsOneWidget);
  });

  testWidgets('a disabled button keeps its own colour, faded', (tester) async {
    await tester.pumpWidget(loopdTestApp(const SizedBox(width: 300, child: LoopdButton(label: 'Save', onTap: null))));
    final box = tester.widget<Container>(
      find.descendant(of: find.byType(LoopdButton), matching: find.byType(Container)),
    );
    expect((box.decoration! as BoxDecoration).color, LoopdColors.dark.money);
    final fade = tester.widget<Opacity>(find.descendant(of: find.byType(LoopdButton), matching: find.byType(Opacity)));
    expect(fade.opacity, 0.4);
  });

  testWidgets("the stack's open area does not cover the card's buttons", (tester) async {
    var opened = false;
    var reviewed = false;
    await tester.pumpWidget(
      loopdTestApp(
        SizedBox(
          width: 360,
          child: LoopdCardStack(
            behind: 2,
            onOpen: () => opened = true,
            top: LoopdCard(
              child: LoopdButton(label: 'Review', onTap: () => reviewed = true),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Review'));
    expect(reviewed, isTrue);
    expect(opened, isFalse);
    expect(tester.getSize(find.byType(LoopdPressable).last).height, greaterThanOrEqualTo(LoopdSize.minTouch));
  });

  testWidgets('an error note shows its message with an icon, in a bordered red box, and is announced', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(loopdTestApp(const LoopdErrorNote('Primary already ends ••2210.')));
    expect(find.text('Primary already ends ••2210.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    final box = tester.widget<Container>(
      find.ancestor(of: find.byIcon(Icons.error_outline_rounded), matching: find.byType(Container)).first,
    );
    final decoration = box.decoration! as BoxDecoration;
    final c = tester.element(find.byType(LoopdErrorNote)).colors;
    expect(decoration.color, c.dangerTint);
    expect(decoration.border, isNotNull);
    expect(
      tester.getSemantics(find.text('Primary already ends ••2210.')),
      matchesSemantics(label: 'Primary already ends ••2210.', isLiveRegion: true),
    );
    semantics.dispose();
  });
}
