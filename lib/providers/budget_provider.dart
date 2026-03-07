import 'package:flutter/material.dart';
import '../models/budget_model.dart';

class BudgetProvider with ChangeNotifier {
  List<Budget> _budgets = []; 

  List<Budget> get budgets => _budgets;

  List<String> get activeCategories {
    return _budgets.map((b) => b.category).toList();
  }

  // --- FUNGSI BARU UNTUK JALAN PINTAS ---
  // Mengambil kode ikon berdasarkan nama kategori agar sinkron dengan Jalan Pintas
  int getIconByCategory(String categoryName) {
    final index = _budgets.indexWhere((b) => b.category == categoryName);
    if (index != -1) {
      return _budgets[index].iconCode;
    }
    return Icons.category.codePoint; // Ikon default jika tidak ditemukan
  }

  void addExpense(String budgetId, double amount) {
    final index = _budgets.indexWhere((b) => b.id == budgetId);
    if (index != -1) {
      _budgets[index].usedAmount += amount;
      notifyListeners(); 
    }
  }

  void addBudget(Budget budget) {
    _budgets.add(budget);
    notifyListeners();
  }

  void updateBudget(String id, String newCategory, double newLimit, int iconCode) {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      _budgets[index] = Budget(
        id: id, 
        category: newCategory, 
        limit: newLimit, 
        iconCode: iconCode,
        usedAmount: _budgets[index].usedAmount
      );
      notifyListeners();
    }
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void clearAllData() {
    _budgets = []; 
    notifyListeners();
  }
}