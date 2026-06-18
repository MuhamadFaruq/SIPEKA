import 'package:sipeka/core/database/database_helper.dart';
import '../models/debt_model.dart';

abstract class DebtLocalDataSource {
  Future<List<DebtModel>> getDebts();
  Future<void> insertDebt(DebtModel debt);
  Future<void> updateDebt(String id, String name, double amount, String notes);
  Future<void> deleteDebt(String id);
  Future<void> markAsPaid(String id, DateTime paidDate);
  Future<void> clearDebts();
}

class DebtLocalDataSourceImpl implements DebtLocalDataSource {
  final DatabaseHelper dbHelper;

  DebtLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<DebtModel>> getDebts() async {
    final maps = await dbHelper.getAllDebts();
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertDebt(DebtModel debt) async {
    await dbHelper.insertDebt(debt.toMap());
  }

  @override
  Future<void> updateDebt(String id, String name, double amount, String notes) async {
    await dbHelper.updateDebt(id, {
      'name': name,
      'amount': amount,
      'notes': notes,
    });
  }

  @override
  Future<void> deleteDebt(String id) async {
    await dbHelper.deleteDebt(id);
  }

  @override
  Future<void> markAsPaid(String id, DateTime paidDate) async {
    await dbHelper.updateDebt(id, {
      'is_paid': 1,
      'paid_date': paidDate.toIso8601String(),
    });
  }

  @override
  Future<void> clearDebts() async {
    await dbHelper.clearDebtTable();
  }
}
