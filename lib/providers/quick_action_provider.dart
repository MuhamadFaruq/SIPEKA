import 'package:flutter/material.dart';
import '../models/quick_action_model.dart';

class QuickActionProvider with ChangeNotifier {
  List<QuickAction> _actions = [];

  List<QuickAction> get actions => _actions;

  void addAction(QuickAction action) {
    _actions.add(action);
    notifyListeners();
  }

  // --- PERBAIKAN 1: Tambahkan fungsi removeAction ---
  void removeAction(String id) {
    _actions.removeWhere((action) => action.id == id);
    notifyListeners();
  }

  // --- PERBAIKAN 2: Tambahkan fungsi updateAction ---
  void updateAction(String id, String newLabel, double newAmount) {
    final index = _actions.indexWhere((action) => action.id == id);
    if (index != -1) {
      _actions[index] = QuickAction(
        id: id,
        label: newLabel,
        category: _actions[index].category, // Tetap gunakan kategori lama
        amount: newAmount,
        icon: _actions[index].icon, // Tetap gunakan ikon lama
      );
      notifyListeners();
    }
  }

  void clearAll() {
    _actions = [];
    notifyListeners();
  }
}