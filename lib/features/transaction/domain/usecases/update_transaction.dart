import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransactionUseCase {
  final TransactionRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<bool> call(TransactionEntity transaction) {
    return repository.updateTransaction(transaction);
  }
}
