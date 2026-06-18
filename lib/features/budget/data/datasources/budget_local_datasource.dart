import 'package:sipeka/core/database/database_helper.dart';
import '../models/budget_model.dart';

abstract class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<void> insertBudget(BudgetModel budget);
  Future<void> updateBudget(String id, String category, double limit, int iconCode);
  Future<void> deleteBudget(String id);
  Future<void> clearBudgets();
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  final DatabaseHelper dbHelper;

  BudgetLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final maps = await dbHelper.getAllBudgets();
    return maps.map((map) => BudgetModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertBudget(BudgetModel budget) async {
    await dbHelper.insertBudget(budget.toMap());
  }

  @override
  Future<void> updateBudget(String id, String category, double limit, int iconCode) async {
    await dbHelper.updateBudget(id, {
      'category': category,
      'limit_amount': limit,
      'icon_code': iconCode,
    });
  }

  @override
  Future<void> deleteBudget(String id) async {
    await dbHelper.deleteBudget(id);
  }

  @override
  Future<void> clearBudgets() async {
    await dbHelper.clearBudgetTable();
  }
}
