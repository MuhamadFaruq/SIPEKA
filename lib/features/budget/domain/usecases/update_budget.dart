import '../repositories/budget_repository.dart';

class UpdateBudgetUseCase {
  final BudgetRepository repository;

  UpdateBudgetUseCase(this.repository);

  Future<void> call({
    required String id,
    required String category,
    required double limit,
    required int iconCode,
  }) {
    return repository.updateBudget(id, category, limit, iconCode);
  }
}
