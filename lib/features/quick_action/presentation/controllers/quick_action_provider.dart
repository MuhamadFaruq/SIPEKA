import 'package:flutter/material.dart';
import '../../domain/entities/quick_action_entity.dart';
import '../../domain/repositories/quick_action_repository.dart';
import '../../data/repositories/quick_action_repository_impl.dart';

class QuickActionProvider with ChangeNotifier {
  final QuickActionRepository repository;

  List<QuickActionEntity> _actions = [];
  
  List<QuickActionEntity> get actions => _actions;

  QuickActionProvider({QuickActionRepository? repository})
      : repository = repository ?? QuickActionRepositoryImpl() {
    loadActions();
  }

  Future<void> loadActions() async {
    try {
      final list = await repository.getQuickActions();
      _actions = List<QuickActionEntity>.from(list);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading quick actions: $e');
    }
  }

  Future<void> addAction(QuickActionEntity action) async {
    _actions.add(action);
    await repository.saveQuickActions(_actions);
    notifyListeners();
  }

  Future<void> removeAction(String id) async {
    _actions.removeWhere((action) => action.id == id);
    await repository.saveQuickActions(_actions);
    notifyListeners();
  }

  Future<void> updateAction(
    String id,
    String newLabel,
    double newAmount,
    String newCategory,
    IconData newIcon,
  ) async {
    final index = _actions.indexWhere((action) => action.id == id);
    if (index != -1) {
      _actions[index] = QuickActionEntity(
        id: id,
        label: newLabel,
        amount: newAmount,
        category: newCategory,
        icon: newIcon,
      );
      await repository.saveQuickActions(_actions);
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _actions = [];
    await repository.saveQuickActions(_actions);
    notifyListeners();
  }
}
