import '../../domain/entities/debt_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_local_datasource.dart';
import '../datasources/debt_remote_datasource.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtLocalDataSource localDataSource;
  final DebtRemoteDataSource remoteDataSource;

  DebtRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<DebtEntity>> getDebts() async {
    return await localDataSource.getDebts();
  }

  @override
  Future<void> addDebt(DebtEntity debt) async {
    await localDataSource.insertDebt(DebtModel.fromEntity(debt));
  }

  @override
  Future<void> updateDebt(String id, String name, double amount, String notes) async {
    await localDataSource.updateDebt(id, name, amount, notes);
  }

  @override
  Future<void> deleteDebt(String id) async {
    await localDataSource.deleteDebt(id);
  }

  @override
  Future<void> markAsPaid(String id, DateTime paidDate) async {
    await localDataSource.markAsPaid(id, paidDate);
  }

  @override
  Future<void> clearDebts() async {
    await localDataSource.clearDebts();
  }
}
