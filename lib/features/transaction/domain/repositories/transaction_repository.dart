import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions();
  Future<bool> addTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
}
