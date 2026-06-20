import '../entities/bill_entity.dart';

abstract class BillRepository {
  Future<List<BillEntity>> getBills();
  Future<bool> addBill(BillEntity bill);
  Future<bool> updateBill(BillEntity bill);
  Future<bool> deleteBill(String id);
}
