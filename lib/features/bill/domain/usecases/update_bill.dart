import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

class UpdateBillUseCase {
  final BillRepository repository;

  UpdateBillUseCase(this.repository);

  Future<bool> call(BillEntity bill) async {
    return await repository.updateBill(bill);
  }
}
