import 'package:flutter_test/flutter_test.dart';
import 'package:sipeka/core/utils/formatters.dart';
import 'package:sipeka/features/budget/domain/entities/budget_entity.dart';
import 'package:sipeka/features/wishlist/domain/entities/wishlist_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/features/transaction/data/models/transaction_model.dart';
import 'package:sipeka/features/debt/domain/entities/debt_entity.dart';
import 'package:sipeka/features/wallet/domain/entities/wallet_entity.dart';
import 'package:sipeka/features/wallet/data/models/wallet_model.dart';
import 'package:sipeka/features/bill/domain/entities/bill_entity.dart';
import 'package:sipeka/features/bill/data/models/bill_model.dart';

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

    test('Simulating transfer transaction balances results in correct wallet-specific balances and unchanged total', () {
      final now = DateTime.now();
      
      // Seed wallets: Wallet A (initial: 100,000) and Wallet B (initial: 50,000)
      const walletA = WalletEntity(id: 'w1', name: 'BCA', initialBalance: 100000.0, iconCode: 1, colorHex: '#000000');
      const walletB = WalletEntity(id: 'w2', name: 'Kas Tunai', initialBalance: 50000.0, iconCode: 2, colorHex: '#000000');
      final wallets = [walletA, walletB];

      // Simulate a transfer of 20,000 from BCA to Kas Tunai
      // This creates 2 transactions:
      final expenseTx = TransactionModel(
        id: 'tx1',
        title: 'Transfer ke Kas Tunai',
        amount: 20000.0,
        date: now,
        type: TransactionType.expense,
        category: 'Transfer',
        wallet: 'BCA',
      );

      final incomeTx = TransactionModel(
        id: 'tx2',
        title: 'Transfer dari BCA',
        amount: 20000.0,
        date: now,
        type: TransactionType.income,
        category: 'Transfer',
        wallet: 'Kas Tunai',
      );

      final transactions = [expenseTx, incomeTx];

      // Helper functions for balance calculations (same logic as in TransactionProvider)
      double getWalletBalance(String walletName) {
        final filtered = transactions.where((tx) => tx.wallet.toLowerCase() == walletName.toLowerCase());
        final double income = filtered
            .where((tx) => tx.type == TransactionType.income)
            .fold(0.0, (sum, item) => sum + item.amount);
        final double expense = filtered
            .where((tx) => tx.type == TransactionType.expense)
            .fold(0.0, (sum, item) => sum + item.amount);
        return income - expense;
      }

      double getTotalBalance() {
        double total = 0.0;
        for (var w in wallets) {
          total += w.initialBalance + getWalletBalance(w.name);
        }
        return total;
      }

      // Assertions
      expect(getWalletBalance('BCA'), -20000.0); // balance decreases by 20,000
      expect(getWalletBalance('Kas Tunai'), 20000.0); // balance increases by 20,000
      
      // Individual wallets balances
      expect(walletA.initialBalance + getWalletBalance('BCA'), 80000.0); // 100,000 - 20,000 = 80,000
      expect(walletB.initialBalance + getWalletBalance('Kas Tunai'), 70000.0); // 50,000 + 20,000 = 70,000
      
      // Consolidated total balance remains unchanged (150,000)
      expect(getTotalBalance(), 150000.0); 
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

  group('WalletEntity & Model Unit Tests', () {
    test('WalletModel converts correctly toMap and fromMap', () {
      const model = WalletModel(
        id: 'w1',
        name: 'Bank Mandiri',
        initialBalance: 500000.0,
        iconCode: 58000,
        colorHex: '#007AFF',
      );

      final map = model.toMap();
      expect(map['id'], 'w1');
      expect(map['name'], 'Bank Mandiri');
      expect(map['initial_balance'], 500000.0);
      expect(map['icon_code'], 58000);
      expect(map['color_hex'], '#007AFF');

      final fromMapModel = WalletModel.fromMap(map);
      expect(fromMapModel.id, model.id);
      expect(fromMapModel.name, model.name);
      expect(fromMapModel.initialBalance, model.initialBalance);
      expect(fromMapModel.iconCode, model.iconCode);
      expect(fromMapModel.colorHex, model.colorHex);
    });

    test('WalletModel.fromEntity creates a valid WalletModel', () {
      const entity = WalletEntity(
        id: 'w2',
        name: 'GoPay',
        initialBalance: 100000.0,
        iconCode: 59000,
        colorHex: '#00B0FF',
      );

      final model = WalletModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.initialBalance, entity.initialBalance);
      expect(model.iconCode, entity.iconCode);
      expect(model.colorHex, entity.colorHex);
    });
  });
 
  group('BillEntity & Model Unit Tests', () {
    test('BillModel converts correctly toMap and fromMap', () {
      final now = DateTime.now();
      final model = BillModel(
        id: 'b1',
        title: 'Netflix Sub',
        amount: 186000.0,
        type: 'Expense',
        category: 'Hiburan',
        wallet: 'BCA',
        frequency: 'monthly',
        startDate: now,
        nextExecutionDate: now.add(const Duration(days: 30)),
        isActive: true,
        remindMe: true,
      );
 
      final map = model.toMap();
      expect(map['id'], 'b1');
      expect(map['title'], 'Netflix Sub');
      expect(map['amount'], 186000.0);
      expect(map['type'], 'Expense');
      expect(map['category'], 'Hiburan');
      expect(map['wallet'], 'BCA');
      expect(map['frequency'], 'monthly');
      expect(map['is_active'], 1);
      expect(map['remind_me'], 1);
 
      final fromMapModel = BillModel.fromMap(map);
      expect(fromMapModel.id, model.id);
      expect(fromMapModel.title, model.title);
      expect(fromMapModel.amount, model.amount);
      expect(fromMapModel.type, model.type);
      expect(fromMapModel.category, model.category);
      expect(fromMapModel.wallet, model.wallet);
      expect(fromMapModel.frequency, model.frequency);
      expect(fromMapModel.isActive, model.isActive);
      expect(fromMapModel.remindMe, model.remindMe);
    });
 
    test('BillModel.fromEntity creates a valid BillModel', () {
      final now = DateTime.now();
      final entity = BillEntity(
        id: 'b2',
        title: 'Internet Indihome',
        amount: 350000.0,
        type: 'Expense',
        category: 'Tagihan & Utilitas',
        wallet: 'BCA',
        frequency: 'monthly',
        startDate: now,
        nextExecutionDate: now.add(const Duration(days: 30)),
        isActive: true,
        remindMe: false,
      );
 
      final model = BillModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.title, entity.title);
      expect(model.amount, entity.amount);
      expect(model.type, entity.type);
      expect(model.category, entity.category);
      expect(model.wallet, entity.wallet);
      expect(model.frequency, entity.frequency);
      expect(model.isActive, entity.isActive);
      expect(model.remindMe, entity.remindMe);
    });
  });
}
