import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import 'package:sipeka/features/transaction/data/models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    return await localDataSource.getTransactions();
  }

  @override
  Future<bool> addTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    return await localDataSource.insertTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await localDataSource.deleteTransaction(id);
  }
}
