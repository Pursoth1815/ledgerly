import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_loopd_app.dart';

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await pumpLoopdApp(tester);
    await tester.tap(find.bySemanticsLabel('Add anything'));
    await tester.pumpAndSettle();
  }

  testWidgets('has the input, five shortcuts and three questions', (tester) async {
    await openSheet(tester);
    expect(find.text('Type a payment, a loan, a task or a question.'), findsOneWidget);
    for (final label in ['Expense', 'Lent', 'Trip', 'Note', 'Task']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final question in ['Who owes me?', 'Next trip', 'Spent this month']) {
      expect(find.text(question), findsOneWidget, reason: question);
    }
  });

  testWidgets('a shortcut says which phase builds its form', (tester) async {
    await openSheet(tester);
    await tester.tap(find.bySemanticsLabel('New Trip'));
    await tester.pump();
    expect(find.text('Trip is built in Phase 5'), findsOneWidget);
  });

  testWidgets('typing works, though nothing is understood until Phase 9', (tester) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextField), 'spent 250 on lunch');
    expect(find.text('spent 250 on lunch'), findsOneWidget);
  });
}
