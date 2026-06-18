import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class AddBudgetUseCase {
  final BudgetRepository repository;

  AddBudgetUseCase(this.repository);

  Future<void> call(BudgetEntity budget) {
    return repository.addBudget(budget);
  }
}
