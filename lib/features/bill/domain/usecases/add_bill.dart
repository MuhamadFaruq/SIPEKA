import '../entities/bill_entity.dart';
import '../repositories/bill_repository.dart';

class AddBillUseCase {
  final BillRepository repository;

  AddBillUseCase(this.repository);

  Future<bool> call(BillEntity bill) async {
    return await repository.addBill(bill);
  }
}
