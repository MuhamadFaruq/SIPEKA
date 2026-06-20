import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

class GetBillsUseCase {
  final BillRepository repository;

  GetBillsUseCase(this.repository);

  Future<List<BillEntity>> call() async {
    return await repository.getBills();
  }
}
