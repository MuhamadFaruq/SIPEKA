import '../entities/quick_action_entity.dart';

abstract class QuickActionRepository {
  Future<List<QuickActionEntity>> getQuickActions();
  Future<void> saveQuickActions(List<QuickActionEntity> actions);
}
