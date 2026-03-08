// lib/providers/debt_provider.dart

import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../utils/database_helper.dart';

class DebtProvider with ChangeNotifier {
  List<Debt> _debts = [];

  List<Debt> get debts => _debts;

  double get totalHutang => _debts
      .where((d) => d.type == 'Borrowed')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalPiutang => _debts
      .where((d) => d.type == 'Lent')
      .fold(0, (sum, item) => sum + item.amount);

  // --- AMBIL DATA DARI DB ---
  Future<void> fetchAndSetDebts() async {
    final dataList = await DatabaseHelper.instance.getAllDebts();
    _debts = dataList.map((item) => Debt(
      id: item['id'],
      name: item['name'],
      amount: item['amount'],
      date: DateTime.parse(item['date']),
      type: item['type'],
    )).toList();
    notifyListeners();
  }

  // --- TAMBAH HUTANG ---
  Future<void> addDebt(Debt debt) async {
    _debts.add(debt);
    notifyListeners();

    await DatabaseHelper.instance.insertDebt({
      'id': debt.id,
      'name': debt.name,
      'amount': debt.amount,
      'date': debt.date.toIso8601String(),
      'type': debt.type,
    });
  }

  // --- UPDATE HUTANG ---
  Future<void> updateDebt(String id, String name, double amount) async {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      _debts[index].name = name;
      _debts[index].amount = amount;
      notifyListeners();

      await DatabaseHelper.instance.updateDebt(id, {
        'name': name,
        'amount': amount,
      });
    }
  }

  // --- HAPUS HUTANG ---
  Future<void> deleteDebt(String id) async {
    _debts.removeWhere((d) => d.id == id);
    notifyListeners();
    await DatabaseHelper.instance.deleteDebt(id);
  }

  // --- FUNGSI RESET UNTUK SETTINGS ---
  void clearAllData() {
    _debts = [];
    notifyListeners();
  }
}