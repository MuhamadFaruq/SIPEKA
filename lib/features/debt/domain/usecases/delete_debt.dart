import '../repositories/debt_repository.dart';

class DeleteDebtUseCase {
  final DebtRepository repository;

  DeleteDebtUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteDebt(id);
  }
}
