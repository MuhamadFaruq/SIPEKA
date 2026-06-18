import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  Future<bool> call(TransactionEntity transaction) async {
    return await repository.addTransaction(transaction);
  }
}
