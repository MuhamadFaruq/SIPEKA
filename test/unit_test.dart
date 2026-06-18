import 'package:flutter_test/flutter_test.dart';
import 'package:sipeka/features/budget/domain/entities/budget_entity.dart';
import 'package:sipeka/features/wishlist/domain/entities/wishlist_entity.dart';

void main() {
  group('BudgetEntity Unit Tests', () {
    test('Percentage should calculate correctly', () {
      final budget = BudgetEntity(
        id: '1',
        category: 'Food',
        iconCode: 0,
        limit: 1000.0,
        usedAmount: 500.0,
      );

      expect(budget.percentage, 0.5);
    });

    test('Percentage should return 0.0 when limit is 0', () {
      final budget = BudgetEntity(
        id: '2',
        category: 'Transport',
        iconCode: 0,
        limit: 0.0,
        usedAmount: 100.0,
      );

      expect(budget.percentage, 0.0);
    });

    test('Percentage should clamp to 1.0 when usedAmount exceeds limit', () {
      final budget = BudgetEntity(
        id: '3',
        category: 'Entertainment',
        iconCode: 0,
        limit: 100.0,
        usedAmount: 150.0,
      );

      expect(budget.percentage, 1.0);
    });
  });

  group('WishlistEntity Unit Tests', () {
    test('Progress should calculate correctly', () {
      final wishlist = WishlistEntity(
        id: '1',
        title: 'New Phone',
        targetAmount: 5000.0,
        savedAmount: 2500.0,
      );

      expect(wishlist.progress, 0.5);
      expect(wishlist.isCompleted, false);
    });

    test('isCompleted should return true when savedAmount equals or exceeds targetAmount', () {
      final wishlist = WishlistEntity(
        id: '2',
        title: 'New Laptop',
        targetAmount: 1000.0,
        savedAmount: 1000.0,
      );

      expect(wishlist.isCompleted, true);

      final wishlist2 = WishlistEntity(
        id: '3',
        title: 'Vacation',
        targetAmount: 1000.0,
        savedAmount: 1200.0,
      );

      expect(wishlist2.isCompleted, true);
    });
  });
}
