import '../entities/budget_entity.dart';

abstract class BudgetRepository {
  Future<List<BudgetEntity>> getBudgets();
  Future<void> addBudget(BudgetEntity budget);
  Future<void> updateBudget(String id, String category, double limit, int iconCode);
  Future<void> deleteBudget(String id);
  Future<void> clearBudgets();
}
