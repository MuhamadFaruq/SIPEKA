import '../repositories/bill_repository.dart';

class DeleteBillUseCase {
  final BillRepository repository;

  DeleteBillUseCase(this.repository);

  Future<bool> call(String id) async {
    return await repository.deleteBill(id);
  }
}
