import 'package:sipeka/core/services/sync_service.dart';
import '../models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<List<BudgetModel>> getBudgetsFromCloud();
  Future<void> syncBudgetsToCloud(List<BudgetModel> budgets);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final SyncService syncService;

  BudgetRemoteDataSourceImpl(this.syncService);

  @override
  Future<List<BudgetModel>> getBudgetsFromCloud() async {
    // Karena cloud restore dinonaktifkan sementara, kita return kosong atau delegasikan
    return [];
  }

  @override
  Future<void> syncBudgetsToCloud(List<BudgetModel> budgets) async {
    // Cloud sync dinonaktifkan sementara
  }
}
