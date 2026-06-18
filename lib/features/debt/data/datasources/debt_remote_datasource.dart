import 'package:sipeka/core/services/sync_service.dart';
import '../models/debt_model.dart';

abstract class DebtRemoteDataSource {
  Future<List<DebtModel>> getDebtsFromCloud();
  Future<void> syncDebtsToCloud(List<DebtModel> debts);
}

class DebtRemoteDataSourceImpl implements DebtRemoteDataSource {
  final SyncService syncService;

  DebtRemoteDataSourceImpl(this.syncService);

  @override
  Future<List<DebtModel>> getDebtsFromCloud() async {
    return [];
  }

  @override
  Future<void> syncDebtsToCloud(List<DebtModel> debts) async {
  }
}
