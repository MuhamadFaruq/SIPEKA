import 'package:sipeka/core/database/database_helper.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  final DatabaseHelper databaseHelper;

  BillRepositoryImpl({DatabaseHelper? dbHelper})
      : databaseHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<BillEntity>> getBills() async {
    final maps = await databaseHelper.getAllBills();
    return maps.map((m) => BillModel.fromMap(m)).toList();
  }

  @override
  Future<bool> addBill(BillEntity bill) async {
    final model = BillModel.fromEntity(bill);
    final result = await databaseHelper.insertBill(model.toMap());
    return result > 0;
  }

  @override
  Future<bool> updateBill(BillEntity bill) async {
    final model = BillModel.fromEntity(bill);
    final result = await databaseHelper.updateBill(bill.id, model.toMap());
    return result > 0;
  }

  @override
  Future<bool> deleteBill(String id) async {
    final result = await databaseHelper.deleteBill(id);
    return result > 0;
  }
}
