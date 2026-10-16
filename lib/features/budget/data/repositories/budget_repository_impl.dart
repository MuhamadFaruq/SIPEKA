import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_firestore_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDataSource dataSource;

  BudgetRepositoryImpl({
    BudgetDataSource? dataSource,
  }) : dataSource = dataSource ?? BudgetFirestoreDataSource();

  @override
  Future<List<BudgetEntity>> getBudgets() async {
    return await dataSource.getBudgets();
  }

  @override
  Future<void> addBudget(BudgetEntity budget) async {
    await dataSource.insertBudget(BudgetModel.fromEntity(budget));
  }

  @override
  Future<void> updateBudget(String id, String category, double limit, int iconCode) async {
    await dataSource.updateBudget(id, category, limit, iconCode);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await dataSource.deleteBudget(id);
  }

  @override
  Future<void> clearBudgets() async {
    await dataSource.clearBudgets();
  }
}
