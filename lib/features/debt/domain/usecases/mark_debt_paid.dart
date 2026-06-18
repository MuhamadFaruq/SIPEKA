import '../repositories/debt_repository.dart';

class MarkDebtPaidUseCase {
  final DebtRepository repository;

  MarkDebtPaidUseCase(this.repository);

  Future<void> call(String id, DateTime paidDate) {
    return repository.markAsPaid(id, paidDate);
  }
}
