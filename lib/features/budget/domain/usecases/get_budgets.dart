import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class GetBudgetsUseCase {
  final BudgetRepository repository;

  GetBudgetsUseCase(this.repository);

  Future<List<BudgetEntity>> call() {
    return repository.getBudgets();
  }
}
