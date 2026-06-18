import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtsUseCase {
  final DebtRepository repository;

  GetDebtsUseCase(this.repository);

  Future<List<DebtEntity>> call() {
    return repository.getDebts();
  }
}
