import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_finance/finance_app.dart';

void main() {
  testWidgets('first-run tour explains swipe-to-delete and can be completed', (
    tester,
  ) async {
    final store = FinanceStore(
      settings: FinanceSettings(cycleStart: DateTime.now()),
      entries: [],
      tutorialPending: true,
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(PulseFinanceApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('A quick tour'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('A quick tour')))
          .textTheme
          .bodyMedium
          ?.fontFamily,
      'Inter',
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Swipe left to delete'), findsOneWidget);
    expect(
      find.textContaining('swipe a transaction from right to left'),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('A quick tour'), findsNothing);
    expect(store.tutorialPending, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard adapts to phone and tablet layouts', (tester) async {
    final store = FinanceStore(
      settings: FinanceSettings(cycleStart: DateTime.now()),
      entries: [],
    );

    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(PulseFinanceApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Overview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('dashboard displays allowance and section navigation works', (
    tester,
  ) async {
    final store = FinanceStore(
      settings: FinanceSettings(cycleStart: DateTime.now()),
      entries: [],
    );
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(PulseFinanceApp(store: store));

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('₦150,000'), findsWidgets);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Allowance configuration'), findsOneWidget);
    expect(find.text('REFILL CYCLE'), findsOneWidget);
    await tester.ensureVisible(find.text('How to use Pulse Finance'));
    await tester.tap(find.text('How to use Pulse Finance'));
    await tester.pumpAndSettle();
    expect(find.text('A quick tour'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('A quick tour'), findsNothing);
  });

  testWidgets('expense entry validates required fields and saves transaction', (
    tester,
  ) async {
    final store = FinanceStore(
      settings: FinanceSettings(cycleStart: DateTime.now()),
      entries: [],
    );
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(PulseFinanceApp(store: store));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount greater than zero'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '2500');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lunch');
    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(store.entries, hasLength(1));
    expect(store.entries.single.title, 'Lunch');
    expect(store.entries.single.amount, 2500);
    expect(store.remaining, 147500);
  });
}
