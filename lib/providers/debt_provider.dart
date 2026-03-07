import 'package:flutter/material.dart';
import '../models/debt_model.dart';

class DebtProvider with ChangeNotifier {
  List<Debt> _debts = []; // Ubah final menjadi List biasa agar bisa dikosongkan

  List<Debt> get debts => _debts;

  // Fungsi Tambah
  void addDebt(Debt debt) {
    _debts.add(debt);
    notifyListeners();
  }

  // Fungsi Update/Edit
  void updateDebt(String id, String newName, double newAmount) {
    final index = _debts.indexWhere((debt) => debt.id == id);
    if (index >= 0) {
      _debts[index] = Debt(
        id: id,
        name: newName,
        amount: newAmount,
        date: _debts[index].date,
        type: _debts[index].type,
      );
      notifyListeners();
    }
  }

  // Fungsi Hapus
  void deleteDebt(String id) {
    _debts.removeWhere((debt) => debt.id == id);
    notifyListeners();
  }

  // --- TAMBAHKAN FUNGSI INI UNTUK RESET DATA ---
  void clearAllData() {
    _debts = []; // Mengosongkan list data hutang
    notifyListeners(); // Memberitahu UI untuk memperbarui tampilan menjadi nol
  }

  // Helper untuk total
  double get totalPiutang => _debts.where((d) => d.type == 'Lent').fold(0.0, (sum, item) => sum + item.amount);
  double get totalHutang => _debts.where((d) => d.type == 'Borrowed').fold(0.0, (sum, item) => sum + item.amount);
}