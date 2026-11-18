import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/ledger/ledger_engine.dart';
import 'package:loopd/core/ledger/ledger_types.dart';
import 'package:loopd/design_system/components/loopd_button.dart';
import 'package:loopd/design_system/components/loopd_dashed_button.dart';
import 'package:loopd/design_system/components/loopd_glyph.dart';
import 'package:loopd/design_system/loopd_colors.dart';
import 'package:loopd/design_system/loopd_theme.dart';
import 'package:loopd/features/expenses/expenses.dart';
import 'package:loopd/features/expenses/presentation/category_sheet.dart' show CategoryTile;

import '../../support/fill_categories.dart';

/// Expense categories on a phone-sized screen, over an in-memory database.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 17, 9);

  Future<LedgerEngine> pumpSheet(
    WidgetTester tester, {
    Future<void> Function(LedgerEngine ledger)? seed,
    bool expenseForm = false,
    bool reduceMotion = false,
  }) async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    addTearDown(database.close);
    final ledger = LedgerEngine(database, clock: () => now);
    await ledger.ensureDefaults();
    await seed?.call(ledger);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), ledgerEngineProvider.overrideWithValue(ledger)],
        child: MaterialApp(
          theme: loopdTheme(Brightness.dark),
          // Choosing categories to delete makes them shake for as long as it
          // lasts, which pumpAndSettle would wait on forever.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: const Scaffold(),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    unawaited(expenseForm ? showExpenseSheet(context, clock: () => now) : showCategorySheet(context, clock: () => now));
    await tester.pumpAndSettle();
    return ledger;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Taps by spoken label, scrolling to it first.
  Future<void> tapLabel(WidgetTester tester, Pattern label) async {
    final target = find.bySemanticsLabel(label).first;
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Reads through the real clock: a Drift watch stream cancelled inside the
  /// test's fake clock leaves the next frame waiting forever.
  Future<T> read<T>(WidgetTester tester, Future<T> Function() query) async => (await tester.runAsync(query)) as T;

  LoopdButton button(WidgetTester tester, String label) =>
      tester.widget<LoopdButton>(find.byWidgetPredicate((w) => w is LoopdButton && w.label == label));

  testWidgets("lists every category with this month's spending", (tester) async {
    await pumpSheet(
      tester,
      seed: (ledger) async {
        final primary = await ledger.addAccount(kind: AccountKind.bank, name: 'Primary', last4: '2210');
        await ledger.recordExpense(
          amountPaise: 324000,
          method: PaymentMethod.upi,
          fundingAccountId: primary,
          categoryId: 'category-food',
          occurredAt: DateTime(2026, 11, 10, 13),
        );
      },
    );
    expect(find.text('Expense categories'), findsOneWidget);
    expect(find.text('Tap one to rename it or change its colour and icon.'), findsOneWidget);
    expect(find.bySemanticsLabel('Food, ₹3,240 this month'), findsOneWidget);
    expect(find.bySemanticsLabel('Snacks, ₹0 this month'), findsOneWidget);
    expect(find.text('New category'), findsOneWidget);
  });

  testWidgets('adds a category, which goes last in the list', (tester) async {
    final ledger = await pumpSheet(tester);
    await tapText(tester, 'New category');
    expect(find.text('New category'), findsOneWidget, reason: 'the title of the form');
    expect(button(tester, 'Add category').onTap, isNull, reason: 'no name yet');
    expect(find.text('Category name'), findsOneWidget, reason: 'the preview before a name');

    await tester.enterText(find.byKey(CategorySheet.nameFieldKey), 'Coffee');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Preview, Coffee'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Colour 15'));
    await tester.tap(find.bySemanticsLabel('Paw icon'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Add category');

    expect(find.text('Added Coffee'), findsOneWidget);
    expect(find.text('Expense categories'), findsOneWidget, reason: 'back on the list');
    final coffee = (await read(tester, () => ledger.watchCategories().first)).last;
    expect((coffee.name, coffee.colour, coffee.icon), ('Coffee', 14, 'paw'));
  });

  testWidgets('New category offers only the colours and icons no category has', (tester) async {
    await pumpSheet(tester);
    await tapText(tester, 'New category');
    final colours = [
      for (var i = 1; i <= 25; i++)
        if (find.bySemanticsLabel('Colour $i').evaluate().isNotEmpty) i,
    ];
    expect(colours, [12, for (var i = 14; i <= 24; i++) i], reason: 'the thirteen defaults use the rest');
    expect(find.bySemanticsLabel('Dots icon'), findsNothing, reason: "Misc's");
    expect(find.bySemanticsLabel('Food icon'), findsNothing);
    expect(find.bySemanticsLabel('Cup icon'), findsNothing);
    final icons = [
      for (final (key, label) in LoopdGlyph.expenseIcons)
        if (find.bySemanticsLabel('$label icon').evaluate().isNotEmpty) key,
    ];
    expect(icons, hasLength(12));
    expect(icons.first, 'phone', reason: 'only the new twelve are free');
    final selected = tester.getSemantics(find.bySemanticsLabel('Colour 12'));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue, reason: 'starts on the first free colour');
  });

  testWidgets('editing offers its own colour and icon besides the free ones', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.bySemanticsLabel('Snacks, ₹0 this month'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Colour 2'), findsOneWidget, reason: 'its own');
    expect(find.bySemanticsLabel('Colour 1'), findsNothing, reason: "Food's");
    expect(find.bySemanticsLabel('Cup icon'), findsOneWidget, reason: 'its own');
    expect(find.bySemanticsLabel('Star icon'), findsNothing, reason: "Fun's");
  });

  testWidgets('at the limit, the note shows and the button deletes instead of adding', (tester) async {
    await pumpSheet(tester, seed: fillCategories, reduceMotion: true);
    expect(find.text('${CategorySheet.fullMessage}. Delete one you added to make room.'), findsOneWidget);
    expect(find.text('New category'), findsNothing);
    await tapText(tester, 'Delete categories');
    expect(find.text('Tick the ones you added. The default ones always stay.'), findsOneWidget);
    expect(button(tester, 'Delete').onTap, isNull, reason: 'nothing ticked yet');
  });

  testWidgets('choosing several to delete: own ones shake with a tick box, defaults stay put', (tester) async {
    final ledger = await pumpSheet(
      tester,
      reduceMotion: true,
      seed: (ledger) async {
        final tea = await ledger.addCategory(name: 'Tea', colour: 11, icon: 'phone');
        await ledger.addCategory(name: 'Juice', colour: 13, icon: 'car');
        final primary = await ledger.addAccount(kind: AccountKind.bank, name: 'Primary', last4: '2210');
        await ledger.recordExpense(
          amountPaise: 4000,
          method: PaymentMethod.upi,
          fundingAccountId: primary,
          categoryId: tea,
          occurredAt: DateTime(2026, 11, 12, 9),
        );
      },
    );
    await tester.tap(find.bySemanticsLabel('Delete categories'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Food, default'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Food, default'));
    await tapLabel(tester, 'Delete Tea');
    await tapLabel(tester, 'Delete Juice');
    await tester.pumpAndSettle();
    await tapText(tester, 'Delete 2 categories');

    expect(find.text('Delete 2 categories?'), findsOneWidget);
    expect(find.text('1 expense will move to Misc.'), findsOneWidget, reason: 'Misc unless you pick another');
    await tester.tap(find.text('Groceries').last);
    await tester.pumpAndSettle();
    expect(find.text('1 expense will move to Groceries.'), findsOneWidget);
    await tapText(tester, 'Delete');

    expect(find.text('Deleted 2 categories · expenses moved to Groceries'), findsOneWidget);
    expect(find.text('Expense categories'), findsOneWidget, reason: 'back on the list');
    final left = await read(tester, () => ledger.watchCategories().first);
    expect(left, hasLength(13));
    final spent = await read(tester, () => ledger.watchCategorySpending(now).first);
    expect(spent['category-groceries'], 4000);
  });

  testWidgets('the rows you can delete shake while choosing, unless motion is reduced', (tester) async {
    await pumpSheet(
      tester,
      seed: (ledger) => ledger.addCategory(name: 'Tea', colour: 11, icon: 'phone'),
    );
    await tester.ensureVisible(find.bySemanticsLabel(RegExp(r'^Tea, ')));
    await tester.pumpAndSettle();
    await tester.longPress(find.bySemanticsLabel(RegExp(r'^Tea, ')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    List<Matrix4> tilts() => [
      for (final t in tester.widgetList<Transform>(
        find.ancestor(of: find.byType(CategoryTile), matching: find.byType(Transform)),
      ))
        t.transform.clone(),
    ];
    final before = tilts();
    await tester.pump(const Duration(milliseconds: 70));
    final after = tilts();
    expect(
      [
        for (var i = 0; i < before.length; i++)
          if (before[i] != after[i]) i,
      ],
      isNotEmpty,
      reason: 'Tea keeps moving',
    );
    expect(find.bySemanticsLabel('Delete Tea'), findsWidgets, reason: 'and starts ticked');
    expect(button(tester, 'Delete 1 category').onTap, isNotNull);
    // Leave without settling: the shake runs until the choosing ends.
    await tester.tap(find.bySemanticsLabel('Back to categories'));
    await tester.pumpAndSettle();
    expect(find.text('Expense categories'), findsOneWidget);
  });

  testWidgets('a category you added can be deleted from its edit form; a default cannot', (tester) async {
    final ledger = await pumpSheet(
      tester,
      seed: (ledger) => ledger.addCategory(name: 'Tea', colour: 11, icon: 'phone'),
    );
    await tester.tap(find.bySemanticsLabel('Snacks, ₹0 this month'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Delete Snacks'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Back to categories'));
    await tester.pumpAndSettle();

    await tapLabel(tester, 'Tea, ₹0 this month');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Delete Tea'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Tea?'), findsOneWidget);
    expect(find.text('No expenses to move.'), findsOneWidget);
    await tapText(tester, 'Delete');
    expect(find.text('Deleted Tea'), findsOneWidget);
    expect(await read(tester, () => ledger.watchCategories().first), hasLength(13));
  });

  testWidgets('there is no close button: back on the form returns to the list, back on the list closes', (
    tester,
  ) async {
    await pumpSheet(tester);
    expect(find.bySemanticsLabel('Close'), findsNothing);
    await tapText(tester, 'New category');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    // What the phone's back button does.
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(CategorySheet), findsOneWidget, reason: 'still open');
    expect(find.text('Expense categories'), findsOneWidget, reason: 'on the list');
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(CategorySheet), findsNothing);
  });

  test('the palette and the icons match the ledger limits', () {
    expect(LoopdCategoryColours.expense, hasLength(LedgerEngine.categoryColours));
    expect(LoopdGlyph.expenseIcons.map((i) => i.$1).toSet(), hasLength(LedgerEngine.categoryMax));
    expect(LedgerEngine.categoryMax, LedgerEngine.categoryColours, reason: 'one colour for each icon');
  });

  testWidgets('a name already used is flagged as you type', (tester) async {
    await pumpSheet(tester);
    await tapText(tester, 'New category');
    await tester.enterText(find.byKey(CategorySheet.nameFieldKey), ' food ');
    await tester.pumpAndSettle();
    expect(find.text('You already have a category called Food.'), findsOneWidget);
    expect(button(tester, 'Add category').onTap, isNull);
  });

  testWidgets('edits a category: rename and recolour, with Save only after a change', (tester) async {
    final ledger = await pumpSheet(tester);
    await tester.tap(find.bySemanticsLabel('Snacks, ₹0 this month'));
    await tester.pumpAndSettle();
    expect(find.text('Edit category'), findsOneWidget);
    expect(button(tester, 'Save changes').onTap, isNull, reason: 'nothing changed yet');

    await tester.enterText(find.byKey(CategorySheet.nameFieldKey), 'Tea and snacks');
    await tester.tap(find.bySemanticsLabel('Colour 16'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Save changes');
    expect(find.text('Saved Tea and snacks'), findsOneWidget);
    final snacks = (await read(
      tester,
      () => ledger.watchCategories().first,
    )).firstWhere((k) => k.id == 'category-snacks');
    expect((snacks.name, snacks.colour), ('Tea and snacks', 15));
  });

  testWidgets('the back arrow returns to the list without saving', (tester) async {
    final ledger = await pumpSheet(tester);
    await tapText(tester, 'New category');
    await tester.enterText(find.byKey(CategorySheet.nameFieldKey), 'Pets');
    await tester.tap(find.bySemanticsLabel('Back to categories'));
    await tester.pumpAndSettle();
    expect(find.text('Expense categories'), findsOneWidget);
    expect(await read(tester, () => ledger.watchCategories().first), hasLength(13));
  });

  /// The keyboard the open text field asked for, such as TextInputType.text.
  String? keyboard(WidgetTester tester) =>
      ((tester.testTextInput.setClientArgs?['inputType'] as Map<String, dynamic>?)?['name']) as String?;

  testWidgets('from the expense form: the number pad closes, the name gets letters, and back leaves it closed', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      expenseForm: true,
      seed: (ledger) => ledger.addAccount(kind: AccountKind.bank, name: 'Primary', last4: '2210', makeDefault: true),
    );
    expect(keyboard(tester), 'TextInputType.number');
    await tester.enterText(find.byKey(ExpenseSheet.amountFieldKey), '90');
    // As tapping "+ New"; a focused field in a test keeps scrolling itself
    // back into view, so the chip is pressed directly.
    tester.widget<LoopdDashedButton>(find.byType(LoopdDashedButton)).onTap!();
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse, reason: 'the number pad closes first');
    await tester.pumpAndSettle();
    expect(find.byType(CategorySheet), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(keyboard(tester), 'TextInputType.text', reason: 'letters for a name');

    await tester.enterText(find.byKey(CategorySheet.nameFieldKey), 'Tea');
    await tester.pumpAndSettle();
    await tapText(tester, 'Add category');
    expect(find.text('Add expense'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse, reason: 'no keyboard back on the form');
    expect(find.text('Save ₹90'), findsOneWidget, reason: 'the amount is kept');
  });

  testWidgets('the expense form adds a category in place and chooses it', (tester) async {
    final ledger = await pumpSheet(
      tester,
      expenseForm: true,
      seed: (ledger) => ledger.addAccount(kind: AccountKind.bank, name: 'Primary', last4: '2210', makeDefault: true),
    );
    await tester.enterText(find.byKey(ExpenseSheet.amountFieldKey), '90');
    // Put the keyboard away, as a tap elsewhere does; a focused field keeps
    // itself on screen and would scroll the list back up.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapText(tester, '+ New');
    expect(find.text('New category'), findsOneWidget);
    expect(find.bySemanticsLabel('Back to categories'), findsNothing, reason: 'no list behind it');
    await tester.enterText(find.byKey(CategorySheet.nameFieldKey), 'Coffee');
    await tester.pumpAndSettle();
    await tapText(tester, 'Add category');

    expect(find.text('Add expense'), findsOneWidget, reason: 'back on the form');
    await tapText(tester, 'Save ₹90');
    final spent = await read(tester, () => ledger.watchCategorySpending(now).first);
    final coffee = (await read(tester, () => ledger.watchCategories().first)).last;
    expect(spent[coffee.id], 9000, reason: 'the new category was chosen');
  });
}
