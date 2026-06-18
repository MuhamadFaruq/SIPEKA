import 'package:sipeka/core/database/database_helper.dart';
import 'package:sipeka/features/transaction/data/models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<bool> insertTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final DatabaseHelper dbHelper;

  TransactionLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final maps = await dbHelper.getAllTransactions();
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<bool> insertTransaction(TransactionModel transaction) async {
    final result = await dbHelper.insertTransaction(transaction.toMap());
    return result != -1;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await dbHelper.deleteTransaction(id);
  }
}
