import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_datasource.dart';
import '../datasources/budget_remote_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;
  final BudgetRemoteDataSource remoteDataSource;

  BudgetRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<BudgetEntity>> getBudgets() async {
    return await localDataSource.getBudgets();
  }

  @override
  Future<void> addBudget(BudgetEntity budget) async {
    await localDataSource.insertBudget(BudgetModel.fromEntity(budget));
  }

  @override
  Future<void> updateBudget(String id, String category, double limit, int iconCode) async {
    await localDataSource.updateBudget(id, category, limit, iconCode);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await localDataSource.deleteBudget(id);
  }

  @override
  Future<void> clearBudgets() async {
    await localDataSource.clearBudgets();
  }
}
