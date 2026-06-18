import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class AddDebtUseCase {
  final DebtRepository repository;

  AddDebtUseCase(this.repository);

  Future<void> call(DebtEntity debt) {
    return repository.addDebt(debt);
  }
}
