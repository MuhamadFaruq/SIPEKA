import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../utils/database_helper.dart';
// import '../services/sync_service.dart'; // [DIKOMENTARI] Sementara tidak digunakan

class BudgetProvider with ChangeNotifier {
  List<Budget> _budgets = []; 
  // final SyncService _syncService = SyncService(); // [DIKOMENTARI] Sementara tidak digunakan

  List<Budget> get budgets => _budgets;

  List<String> get activeCategories {
    return _budgets.map((b) => b.category).toList();
  }

  // --- FUNGSI AMBIL DATA DARI DATABASE (LOCAL ONLY) ---
  Future<void> fetchAndSetBudgets() async {
    final dataList = await DatabaseHelper.instance.getAllBudgets();
    _budgets = dataList.map((item) => Budget(
      id: item['id'],
      category: item['category'],
      limit: (item['limit_amount'] as num).toDouble(),
      iconCode: item['icon_code'],
      usedAmount: 0.0, 
    )).toList();
    notifyListeners();
  }

  Future<void> fetchBudgets() async {
    await fetchAndSetBudgets();
  }

  // --- CRUD FUNCTIONS (LOCAL DATABASE ONLY) ---

  Future<void> addBudget(Budget budget) async {
    // Optimistic UI: Update UI dulu agar terasa cepat
    _budgets.add(budget);
    notifyListeners();

    await DatabaseHelper.instance.insertBudget({
      'id': budget.id,
      'category': budget.category,
      'limit_amount': budget.limit,
      'icon_code': budget.iconCode,
    });

    // _syncCloud(); // [DIKOMENTARI] Skip sinkronisasi cloud
  }

  Future<void> updateBudget(String id, String newCategory, double newLimit, int iconCode) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      double currentUsed = _budgets[index].usedAmount;

      _budgets[index] = Budget(
        id: id, 
        category: newCategory, 
        limit: newLimit, 
        iconCode: iconCode,
        usedAmount: currentUsed 
      );
      notifyListeners();

      await DatabaseHelper.instance.updateBudget(id, {
        'category': newCategory,
        'limit_amount': newLimit,
        'icon_code': iconCode,
      });

      // _syncCloud(); // [DIKOMENTARI] Skip sinkronisasi cloud
    }
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
    await DatabaseHelper.instance.deleteBudget(id);

    // _syncCloud(); // [DIKOMENTARI] Skip sinkronisasi cloud
  }

  // --- FUNGSI RESTORE BUDGET (NON-AKTIF) ---
  Future<void> restoreBudgetsFromCloud() async {
    debugPrint("Fitur Cloud Restore sedang dinonaktifkan sementara.");
    /* [DIKOMENTARI]
    try {
      final List<Budget> cloudBudgets = await _syncService.getBudgetsFromCloud();
      if (cloudBudgets.isNotEmpty) {
        await DatabaseHelper.instance.clearBudgetTable(); 

        for (var b in cloudBudgets) {
          await DatabaseHelper.instance.insertBudget({
            'id': b.id,
            'category': b.category,
            'limit_amount': b.limit,
            'icon_code': b.iconCode,
          });
        }
        await fetchAndSetBudgets();
      }
    } catch (e) {
      debugPrint("Gagal restore budget: $e");
    }
    */
  }

  // Helper Sync (NON-AKTIF)
  void _syncCloud() {
    /* [DIKOMENTARI]
    _syncService.syncBudgets(_budgets).catchError((e) {
      debugPrint("Gagal sinkron budget ke cloud: $e");
    });
    */
  }

  // --- FUNGSI UTILITAS LAINNYA ---
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