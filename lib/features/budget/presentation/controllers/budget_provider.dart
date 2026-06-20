import 'package:flutter/material.dart';
import 'package:sipeka/core/database/database_helper.dart';
import 'package:sipeka/core/services/sync_service.dart';

import '../../domain/entities/budget_entity.dart';
import '../../domain/usecases/add_budget.dart';
import '../../domain/usecases/delete_budget.dart';
import '../../domain/usecases/get_budgets.dart';
import '../../domain/usecases/update_budget.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/datasources/budget_local_datasource.dart';
import '../../data/datasources/budget_remote_datasource.dart';

class BudgetProvider with ChangeNotifier {
  final GetBudgetsUseCase getBudgetsUseCase;
  final AddBudgetUseCase addBudgetUseCase;
  final UpdateBudgetUseCase updateBudgetUseCase;
  final DeleteBudgetUseCase deleteBudgetUseCase;

  List<BudgetEntity> _budgets = []; 
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<BudgetEntity> get budgets => _budgets;

  List<String> get activeCategories {
    return _budgets.map((b) => b.category).toList();
  }

  BudgetProvider({
    GetBudgetsUseCase? getBudgetsUseCase,
    AddBudgetUseCase? addBudgetUseCase,
    UpdateBudgetUseCase? updateBudgetUseCase,
    DeleteBudgetUseCase? deleteBudgetUseCase,
  })  : getBudgetsUseCase = getBudgetsUseCase ??
            GetBudgetsUseCase(
              BudgetRepositoryImpl(
                localDataSource: BudgetLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: BudgetRemoteDataSourceImpl(SyncService()),
              ),
            ),
        addBudgetUseCase = addBudgetUseCase ??
            AddBudgetUseCase(
              BudgetRepositoryImpl(
                localDataSource: BudgetLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: BudgetRemoteDataSourceImpl(SyncService()),
              ),
            ),
        updateBudgetUseCase = updateBudgetUseCase ??
            UpdateBudgetUseCase(
              BudgetRepositoryImpl(
                localDataSource: BudgetLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: BudgetRemoteDataSourceImpl(SyncService()),
              ),
            ),
        deleteBudgetUseCase = deleteBudgetUseCase ??
            DeleteBudgetUseCase(
              BudgetRepositoryImpl(
                localDataSource: BudgetLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: BudgetRemoteDataSourceImpl(SyncService()),
              ),
            );

  Future<void> fetchAndSetBudgets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final dataList = await getBudgetsUseCase();
      _budgets = List<BudgetEntity>.from(dataList);
    } catch (e) {
      debugPrint("Error fetching budgets: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBudgets() async {
    await fetchAndSetBudgets();
  }

  Future<void> addBudget(BudgetEntity budget) async {
    _budgets.add(budget);
    notifyListeners();

    try {
      await addBudgetUseCase(budget);
      debugPrint("BUDGET_PROVIDER: Berhasil simpan anggaran '${budget.category}'");
    } catch (e) {
      // Rollback jika gagal
      debugPrint("BUDGET_PROVIDER: ERROR simpan anggaran '${budget.category}': $e");
      _budgets.removeWhere((b) => b.id == budget.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBudget(String id, String newCategory, double newLimit, int iconCode) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      double currentUsed = _budgets[index].usedAmount;
      final oldBudget = _budgets[index];

      _budgets[index] = BudgetEntity(
        id: id, 
        category: newCategory, 
        limit: newLimit, 
        iconCode: iconCode,
        usedAmount: currentUsed 
      );
      notifyListeners();

      try {
        await updateBudgetUseCase(
          id: id,
          category: newCategory,
          limit: newLimit,
          iconCode: iconCode,
        );
      } catch (e) {
        debugPrint("Error updating budget: $e");
        // Rollback memory jika gagal
        _budgets[index] = oldBudget;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> deleteBudget(String id) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      final oldBudget = _budgets[index];
      _budgets.removeAt(index);
      notifyListeners();
      try {
        await deleteBudgetUseCase(id);
      } catch (e) {
        debugPrint("Error deleting budget: $e");
        // Rollback memory jika gagal
        _budgets.insert(index, oldBudget);
        notifyListeners();
        rethrow;
      }
    }
  }

  int getIconByCategory(String categoryName) {
    final index = _budgets.indexWhere((b) => b.category == categoryName);
    if (index != -1) {
      return _budgets[index].iconCode;
    }
    return Icons.category.codePoint; 
  }

  void addExpense(String budgetId, double amount) {
    final index = _budgets.indexWhere((b) => b.id == budgetId);
    if (index != -1) {
      _budgets[index].usedAmount += amount;
      notifyListeners(); 
    }
  }

  void clearAllData() {
    _budgets = []; 
    notifyListeners();
    DatabaseHelper.instance.clearBudgetTable();
  }
}
