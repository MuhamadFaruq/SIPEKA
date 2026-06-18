import 'package:sipeka/core/services/sync_service.dart';
import 'package:sipeka/features/transaction/data/models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getTransactionsFromCloud();
  Future<void> syncTransactionsToCloud(List<TransactionModel> transactions);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final SyncService syncService;

  TransactionRemoteDataSourceImpl(this.syncService);

  @override
  Future<List<TransactionModel>> getTransactionsFromCloud() async {
    // In Clean Architecture, we map the transactions returned by SyncService to our feature's TransactionModel
    final result = await syncService.getTransactionsFromCloud();
    return result.map((tx) => TransactionModel(
      id: tx.id,
      title: tx.title,
      amount: tx.amount,
      date: tx.date,
      type: tx.type,
      category: tx.category,
      wallet: tx.wallet,
      source: tx.source,
    )).toList();
  }

  @override
  Future<void> syncTransactionsToCloud(List<TransactionModel> transactions) async {
    // Convert TransactionModel to the legacy Transaction model expected by SyncService
    final legacyTransactions = transactions.map((tx) => tx).toList();
    await syncService.syncTransactions(legacyTransactions);
  }
}
