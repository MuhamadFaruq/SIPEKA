import 'package:sipeka/core/utils/storage.dart';
import '../../domain/entities/quick_action_entity.dart';
import '../../domain/repositories/quick_action_repository.dart';
import '../models/quick_action_model.dart';

class QuickActionRepositoryImpl implements QuickActionRepository {
  @override
  Future<List<QuickActionEntity>> getQuickActions() async {
    final list = await Storage.loadQuickActions();
    return list.map((map) => QuickActionModel.fromMap(map)).toList();
  }

  @override
  Future<void> saveQuickActions(List<QuickActionEntity> actions) async {
    final list = actions.map((a) => QuickActionModel.fromEntity(a).toMap()).toList();
    await Storage.saveQuickActions(list);
  }
}
