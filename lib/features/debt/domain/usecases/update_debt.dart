import '../repositories/debt_repository.dart';

class UpdateDebtUseCase {
  final DebtRepository repository;

  UpdateDebtUseCase(this.repository);

  Future<void> call({
    required String id,
    required String name,
    required double amount,
    required String notes,
  }) {
    return repository.updateDebt(id, name, amount, notes);
  }
}
