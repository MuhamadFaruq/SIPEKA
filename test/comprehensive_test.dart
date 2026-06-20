import 'package:flutter_test/flutter_test.dart';
import 'package:sipeka/core/utils/formatters.dart';
import 'package:sipeka/features/budget/domain/entities/budget_entity.dart';
import 'package:sipeka/features/wishlist/domain/entities/wishlist_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/features/transaction/data/models/transaction_model.dart';
import 'package:sipeka/features/debt/domain/entities/debt_entity.dart';

void main() {
  group('Formatters Unit Tests', () {
    test('formatCurrency converts double correctly to IDR rupiah string', () {
      expect(Formatters.formatCurrency(15000), 'Rp 15.000');
      expect(Formatters.formatCurrency(0), 'Rp 0');
      expect(Formatters.formatCurrency(2500000), 'Rp 2.500.000');
    });

    test('formatCurrencyNoSymbol converts double correctly without Rp prefix', () {
      expect(Formatters.formatCurrencyNoSymbol(15000), '15.000');
      expect(Formatters.formatCurrencyNoSymbol(0), '0');
      expect(Formatters.formatCurrencyNoSymbol(1250350), '1.250.350');
    });

    test('formatPercentage converts double value to percentage string', () {
      expect(Formatters.formatPercentage(45.5), '45.5%');
      expect(Formatters.formatPercentage(100), '100.0%');
      expect(Formatters.formatPercentage(0.0), '0.0%');
    });

    test('CurrencyInputFormatter formats user typing as IDR decimal format', () {
      final formatter = CurrencyInputFormatter();
      
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: '15000');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      
      expect(result.text, '15.000');
      expect(result.selection.baseOffset, 6);
    });
  });

  group('BudgetEntity Unit Tests', () {
    test('percentage calculates limit usage correctly', () {
      final budget = BudgetEntity(
        id: 'b1',
        category: 'Makan',
        iconCode: 123,
        limit: 500000,
        usedAmount: 125000,
      );
      expect(budget.percentage, 0.25);
    });

    test('percentage returns 0.0 when limit is 0', () {
      final budget = BudgetEntity(
        id: 'b2',
        category: 'Lainnya',
        iconCode: 123,
        limit: 0,
        usedAmount: 100000,
      );
      expect(budget.percentage, 0.0);
    });

    test('percentage clamps to 1.0 when used exceeds limit', () {
      final budget = BudgetEntity(
        id: 'b3',
        category: 'Belanja',
        iconCode: 123,
        limit: 100000,
        usedAmount: 150000,
      );
      expect(budget.percentage, 1.0);
    });
  });

  group('WishlistEntity Unit Tests', () {
    test('progress calculates correct saved ratio', () {
      final wishlist = WishlistEntity(
        id: 'w1',
        title: 'Beli Sepatu',
        targetAmount: 1000000,
        savedAmount: 300000,
      );
      expect(wishlist.progress, 0.3);
      expect(wishlist.isCompleted, false);
    });

    test('isCompleted returns true when target is reached or exceeded', () {
      final wishlist1 = WishlistEntity(
        id: 'w2',
        title: 'Tabungan HP',
        targetAmount: 3000000,
        savedAmount: 3000000,
      );
      expect(wishlist1.isCompleted, true);

      final wishlist2 = WishlistEntity(
        id: 'w3',
        title: 'Tabungan Wisata',
        targetAmount: 500000,
        savedAmount: 600000,
      );
      expect(wishlist2.isCompleted, true);
    });
  });

  group('TransactionEntity & Model Unit Tests', () {
    test('TransactionModel converts correctly toMap and fromMap', () {
      final now = DateTime.now();
      final model = TransactionModel(
        id: 'tx1',
        title: 'Beli Kopi',
        amount: 25000,
        date: now,
        type: TransactionType.expense,
        category: 'Minum',
        wallet: 'Dompet',
        source: 'Voice Command',
      );

      final map = model.toMap();
      expect(map['id'], 'tx1');
      expect(map['title'], 'Beli Kopi');
      expect(map['amount'], 25000.0);
      expect(map['type'], 'Expense');
      expect(map['category'], 'Minum');
      expect(map['source'], 'Voice Command');

      final fromMapModel = TransactionModel.fromMap(map);
      expect(fromMapModel.id, model.id);
      expect(fromMapModel.title, model.title);
      expect(fromMapModel.amount, model.amount);
      expect(fromMapModel.type, model.type);
      expect(fromMapModel.category, model.category);
      expect(fromMapModel.source, model.source);
    });
  });

  group('DebtEntity Unit Tests', () {
    test('Debt status fields map correctly', () {
      final debt = DebtEntity(
        id: 'd1',
        name: 'Budi',
        amount: 150000,
        date: DateTime.now(),
        type: 'Borrowed',
        isPaid: false,
      );

      expect(debt.isPaid, false);
      expect(debt.type, 'Borrowed');
      
      debt.isPaid = true;
      debt.paidDate = DateTime.now();
      expect(debt.isPaid, true);
      expect(debt.paidDate, isNotNull);
    });
  });
}
