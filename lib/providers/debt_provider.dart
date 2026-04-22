import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../utils/database_helper.dart';
// import '../services/sync_service.dart'; // 1. DIKOMENTARI: Menghentikan ketergantungan Firebase

class DebtProvider with ChangeNotifier {
  List<Debt> _debts = [];
  // final SyncService _syncService = SyncService(); // 2. DIKOMENTARI: Tidak perlu inisialisasi cloud

  List<Debt> get debts => _debts;

  double get totalHutang => _debts
      .where((d) => d.type == 'Borrowed' && !d.isPaid)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalPiutang => _debts
      .where((d) => d.type == 'Lent' && !d.isPaid)
      .fold(0, (sum, item) => sum + item.amount);

  Future<void> fetchAndSetDebts() async {
    final dataList = await DatabaseHelper.instance.getAllDebts();
    _debts = dataList.map((item) => Debt(
      id: item['id'],
      name: item['name'],
      amount: (item['amount'] as num).toDouble(),
      date: DateTime.parse(item['date']),
      type: item['type'],
      isPaid: item['is_paid'] == 1, 
      paidDate: item['paid_date'] != null ? DateTime.parse(item['paid_date']) : null,
      notes: item['notes'], 
    )).toList();
    notifyListeners();
  }

  Future<void> addDebt(Debt debt) async {
    _debts.add(debt);
    notifyListeners();

    await DatabaseHelper.instance.insertDebt({
      'id': debt.id,
      'name': debt.name,
      'amount': debt.amount,
      'date': debt.date.toIso8601String(),
      'type': debt.type,
      'is_paid': 0,
      'paid_date': null,
      'notes': debt.notes,
    });

    // 3. DIKOMENTARI: Sinkronisasi ke Cloud dimatikan
    // _syncCloud();
  }

  Future<void> markAsPaid(String id) async {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      DateTime now = DateTime.now();
      _debts[index].isPaid = true;
      _debts[index].paidDate = now;
      notifyListeners();

      await DatabaseHelper.instance.updateDebt(id, {
        'is_paid': 1,
        'paid_date': now.toIso8601String(),
      });

      // 4. DIKOMENTARI: Sinkronisasi status lunas dimatikan
      // _syncCloud();
    }
  }

  Future<void> updateDebt(String id, String name, double amount, String notes) async {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      _debts[index] = Debt(
        id: id,
        name: name,
        amount: amount,
        notes: notes,
        date: _debts[index].date,
        type: _debts[index].type,
        isPaid: _debts[index].isPaid,
        paidDate: _debts[index].paidDate,
      );
      
      notifyListeners();

      await DatabaseHelper.instance.updateDebt(id, {
        'name': name,
        'amount': amount,
        'notes': notes,
      });

      // 5. DIKOMENTARI: Update cloud dimatikan
      // _syncCloud();
    }
  }

  Future<void> deleteDebt(String id) async {
    _debts.removeWhere((d) => d.id == id);
    notifyListeners();
    await DatabaseHelper.instance.deleteDebt(id);

    // 6. DIKOMENTARI: Hapus data cloud dimatikan
    // _syncCloud();
  }

  // DIKOMENTARI: Fungsi pembantu dimatikan sementara
  /*
  void _syncCloud() {
    _syncService.syncDebts(_debts).catchError((e) {
      debugPrint("Gagal sinkron hutang ke cloud: $e");
    });
  }
  */

  // DIKOMENTARI: Fungsi Restore Cloud dimatikan
  /*
  Future<void> restoreDebtsFromCloud() async {
    // ... logic restore
  }
  */

  void clearAllData() {
    _debts = [];
    notifyListeners();
  }
}