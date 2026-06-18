import '../entities/debt_entity.dart';

abstract class DebtRepository {
  Future<List<DebtEntity>> getDebts();
  Future<void> addDebt(DebtEntity debt);
  Future<void> updateDebt(String id, String name, double amount, String notes);
  Future<void> deleteDebt(String id);
  Future<void> markAsPaid(String id, DateTime paidDate);
  Future<void> clearDebts();
}
