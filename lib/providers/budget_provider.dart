import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../utils/database_helper.dart';

class BudgetProvider with ChangeNotifier {
  List<Budget> _budgets = []; 

  List<Budget> get budgets => _budgets;

  List<String> get activeCategories {
    return _budgets.map((b) => b.category).toList();
  }

  // --- FUNGSI AMBIL DATA DARI DATABASE ---
  Future<void> fetchAndSetBudgets() async {
    final dataList = await DatabaseHelper.instance.getAllBudgets();
    _budgets = dataList.map((item) => Budget(
      id: item['id'],
      category: item['category'],
      limit: item['limit_amount'], // Menyesuaikan dengan kolom di database
      iconCode: item['icon_code'],
      // Note: usedAmount biasanya dihitung dinamis dari transaksi, 
      // tapi jika kamu menyimpannya di model, kita set 0.0 dulu saat fetch
      usedAmount: 0.0, 
    )).toList();
    notifyListeners();
  }

  // --- FUNGSI IKON UNTUK JALAN PINTAS ---
  int getIconByCategory(String categoryName) {
    final index = _budgets.indexWhere((b) => b.category == categoryName);
    if (index != -1) {
      return _budgets[index].iconCode;
    }
    return Icons.category.codePoint; 
  }

  // --- CRUD FUNCTIONS (DENGAN SQLITE) ---

  Future<void> addBudget(Budget budget) async {
    _budgets.add(budget);
    notifyListeners();

    // Simpan ke SQLite
    await DatabaseHelper.instance.insertBudget({
      'id': budget.id,
      'category': budget.category,
      'limit_amount': budget.limit,
      'icon_code': budget.iconCode,
    });
  }

  Future<void> updateBudget(String id, String newCategory, double newLimit, int iconCode) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      // Simpan nilai usedAmount yang lama agar tidak reset jadi 0 saat diupdate
      double currentUsed = _budgets[index].usedAmount;

      _budgets[index] = Budget(
        id: id, 
        category: newCategory, 
        limit: newLimit, 
        iconCode: iconCode,
        usedAmount: currentUsed // Tetap gunakan nilai lama
      );
      notifyListeners();

      await DatabaseHelper.instance.updateBudget(id, {
        'category': newCategory,
        'limit_amount': newLimit,
        'icon_code': iconCode,
      });
    }
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();

    // Hapus di SQLite
    await DatabaseHelper.instance.deleteBudget(id);
  }
  

  // Digunakan saat transaksi bertambah untuk update tampilan progress bar
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
    // Jika ingin hapus permanen semua di database, panggil fungsi delete khusus di DatabaseHelper
  }
}