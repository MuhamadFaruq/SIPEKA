import '../../domain/entities/debt_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_firestore_datasource.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtDataSource dataSource;

  DebtRepositoryImpl({
    DebtDataSource? dataSource,
  }) : dataSource = dataSource ?? DebtFirestoreDataSource();

  @override
  Future<List<DebtEntity>> getDebts() async {
    return await dataSource.getDebts();
  }

  @override
  Future<void> addDebt(DebtEntity debt) async {
    await dataSource.insertDebt(DebtModel.fromEntity(debt));
  }

  @override
  Future<void> updateDebt(String id, String name, double amount, String notes) async {
    await dataSource.updateDebt(id, name, amount, notes);
  }

  @override
  Future<void> deleteDebt(String id) async {
    await dataSource.deleteDebt(id);
  }

  @override
  Future<void> markAsPaid(String id, DateTime paidDate) async {
    await dataSource.markAsPaid(id, paidDate);
  }

  @override
  Future<void> clearDebts() async {
    await dataSource.clearDebts();
  }
}
