import 'package:sipeka/features/bill/data/datasources/bill_firestore_datasource.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  final BillDataSource dataSource;

  BillRepositoryImpl({BillDataSource? dataSource})
      : dataSource = dataSource ?? BillFirestoreDataSource();

  @override
  Future<List<BillEntity>> getBills() async {
    return await dataSource.getBills();
  }

  @override
  Future<bool> addBill(BillEntity bill) async {
    final model = BillModel.fromEntity(bill);
    return await dataSource.insertBill(model);
  }

  @override
  Future<bool> updateBill(BillEntity bill) async {
    final model = BillModel.fromEntity(bill);
    return await dataSource.updateBill(model);
  }

  @override
  Future<bool> deleteBill(String id) async {
    return await dataSource.deleteBill(id);
  }
}
