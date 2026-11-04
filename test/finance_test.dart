import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_finance/finance_app.dart';

void main() {
  group('allowance cycle', () {
    test(
      'monthly refill clamps to February and retains the original anchor',
      () async {
        final store = FinanceStore(
          settings: FinanceSettings(
            cycle: 'Monthly',
            cycleStart: DateTime(2026, 1, 31),
            cycleAnchorDay: 31,
          ),
          entries: [],
        );

        await store.advanceAllowanceCycle(DateTime(2026, 3, 5));

        expect(store.settings.cycleStart, DateTime(2026, 2, 28));
        expect(store.remaining, 150000);
        await store.advanceAllowanceCycle(DateTime(2026, 3, 31));
        expect(store.settings.cycleStart, DateTime(2026, 3, 31));
      },
    );

    test('weekly refills advance by full seven-day intervals', () async {
      final store = FinanceStore(
        settings: FinanceSettings(
          cycle: 'Weekly',
          cycleStart: DateTime(2026, 1, 1),
        ),
        entries: [],
      );

      await store.advanceAllowanceCycle(DateTime(2026, 1, 20));

      expect(store.settings.cycleStart, DateTime(2026, 1, 15));
      await store.advanceAllowanceCycle(DateTime(2026, 1, 22));
      expect(store.settings.cycleStart, DateTime(2026, 1, 22));
    });
  });

  test('income credits and expenses debit the remaining allowance', () {
    final store = FinanceStore(
      settings: FinanceSettings(cycleStart: DateTime(2026, 1, 1)),
      entries: [
        FinanceEntry(
          id: 'income',
          title: 'Top up',
          category: 'Allowance & Income',
          amount: 20000,
          date: DateTime(2026, 1, 5),
          income: true,
        ),
        FinanceEntry(
          id: 'expense',
          title: 'Lunch',
          category: 'Food & Cafeteria',
          amount: 5000,
          date: DateTime(2026, 1, 5),
          income: false,
        ),
      ],
    );

    expect(store.cycleIncome, 20000);
    expect(store.cycleSpend, 5000);
    expect(store.remaining, 165000);
  });

  test('backup round-trip preserves settings and transaction records', () {
    final original = FinanceStore(
      settings: FinanceSettings(
        cycle: 'Weekly',
        cycleStart: DateTime(2026, 3, 1),
        currency: 'USD',
        categories: ['Food', 'Allowance & Income'],
      ),
      entries: [
        FinanceEntry(
          id: 'entry-1',
          title: 'Lunch',
          category: 'Food',
          amount: 12.5,
          date: DateTime(2026, 3, 2),
          income: false,
          notes: 'Campus',
        ),
      ],
    );

    final restored = FinanceStore.fromJson(original.toJson());

    expect(restored.settings.cycle, 'Weekly');
    expect(restored.settings.currency, 'USD');
    expect(restored.entries.single.title, 'Lunch');
    expect(restored.entries.single.notes, 'Campus');
  });
}
