import 'package:flutter/material.dart';

import '../../domain/entities/debt_entity.dart';
import '../../domain/usecases/add_debt.dart';
import '../../domain/usecases/delete_debt.dart';
import '../../domain/usecases/get_debts.dart';
import '../../domain/usecases/update_debt.dart';
import '../../domain/usecases/mark_debt_paid.dart';
import '../../data/repositories/debt_repository_impl.dart';

class DebtProvider with ChangeNotifier {
  final GetDebtsUseCase getDebtsUseCase;
  final AddDebtUseCase addDebtUseCase;
  final UpdateDebtUseCase updateDebtUseCase;
  final DeleteDebtUseCase deleteDebtUseCase;
  final MarkDebtPaidUseCase markDebtPaidUseCase;

  List<DebtEntity> _debts = [];

  List<DebtEntity> get debts => _debts;

  double get totalHutang => _debts
      .where((d) => d.type == 'Borrowed' && !d.isPaid)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalPiutang => _debts
      .where((d) => d.type == 'Lent' && !d.isPaid)
      .fold(0, (sum, item) => sum + item.amount);

  DebtProvider({
    GetDebtsUseCase? getDebtsUseCase,
    AddDebtUseCase? addDebtUseCase,
    UpdateDebtUseCase? updateDebtUseCase,
    DeleteDebtUseCase? deleteDebtUseCase,
    MarkDebtPaidUseCase? markDebtPaidUseCase,
  })  : getDebtsUseCase = getDebtsUseCase ??
            GetDebtsUseCase(DebtRepositoryImpl()),
        addDebtUseCase = addDebtUseCase ??
            AddDebtUseCase(DebtRepositoryImpl()),
        updateDebtUseCase = updateDebtUseCase ??
            UpdateDebtUseCase(DebtRepositoryImpl()),
        deleteDebtUseCase = deleteDebtUseCase ??
            DeleteDebtUseCase(DebtRepositoryImpl()),
        markDebtPaidUseCase = markDebtPaidUseCase ??
            MarkDebtPaidUseCase(DebtRepositoryImpl());

  Future<void> fetchAndSetDebts() async {
    try {
      final dataList = await getDebtsUseCase();
      _debts = List<DebtEntity>.from(dataList);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching debts: $e");
    }
  }

  Future<void> addDebt(DebtEntity debt) async {
    _debts.add(debt);
    notifyListeners();

    try {
      await addDebtUseCase(debt);
      debugPrint("DEBT_PROVIDER: Berhasil simpan hutang '${debt.name}'");
    } catch (e) {
      debugPrint("DEBT_PROVIDER: ERROR simpan hutang '${debt.name}': $e");
      _debts.removeWhere((d) => d.id == debt.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsPaid(String id) async {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      DateTime now = DateTime.now();
      final oldIsPaid = _debts[index].isPaid;
      final oldPaidDate = _debts[index].paidDate;

      _debts[index].isPaid = true;
      _debts[index].paidDate = now;
      notifyListeners();

      try {
        await markDebtPaidUseCase(id, now);
      } catch (e) {
        debugPrint("Error marking debt as paid: $e");
        // Rollback memory jika gagal
        _debts[index].isPaid = oldIsPaid;
        _debts[index].paidDate = oldPaidDate;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> updateDebt(String id, String name, double amount, String notes) async {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      final oldDebt = _debts[index];

      _debts[index] = DebtEntity(
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

      try {
        await updateDebtUseCase(
          id: id,
          name: name,
          amount: amount,
          notes: notes,
        );
      } catch (e) {
        debugPrint("Error updating debt: $e");
        // Rollback memory jika gagal
        _debts[index] = oldDebt;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> deleteDebt(String id) async {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      final oldDebt = _debts[index];
      _debts.removeAt(index);
      notifyListeners();
      try {
        await deleteDebtUseCase(id);
      } catch (e) {
        debugPrint("Error deleting debt: $e");
        // Rollback memory jika gagal
        _debts.insert(index, oldDebt);
        notifyListeners();
        rethrow;
      }
    }
  }

  void clearAllData() {
    _debts = [];
    notifyListeners();
    DebtRepositoryImpl().dataSource.clearDebts();
  }
}
