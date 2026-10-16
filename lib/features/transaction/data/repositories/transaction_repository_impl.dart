import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_firestore_datasource.dart';
import 'package:sipeka/features/transaction/data/models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDataSource dataSource;

  TransactionRepositoryImpl({
    TransactionDataSource? dataSource,
  }) : dataSource = dataSource ?? TransactionFirestoreDataSource();

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    return await dataSource.getTransactions();
  }

  @override
  Future<bool> addTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    return await dataSource.insertTransaction(model);
  }

  @override
  Future<bool> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    return await dataSource.updateTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await dataSource.deleteTransaction(id);
  }
}
