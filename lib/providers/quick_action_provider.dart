import 'dart:convert'; // Untuk jsonEncode & jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quick_action_model.dart';

class QuickActionProvider with ChangeNotifier {
  List<QuickAction> _actions = [];
  List<QuickAction> get actions => _actions;

  QuickActionProvider() {
    loadActions();
  }

  // FUNGSI SIMPAN KE MEMORI HP
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List Object ke List Map, lalu ke String JSON
    final String encodedData = jsonEncode(_actions.map((a) => a.toMap()).toList());
    await prefs.setString('saved_quick_actions', encodedData);
  }

  // FUNGSI AMBIL DARI MEMORI HP
  Future<void> loadActions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('saved_quick_actions');
    
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      _actions = decodedData.map((item) => QuickAction.fromMap(item)).toList();
      notifyListeners();
    }
  }

  void addAction(QuickAction action) {
    _actions.add(action);
    _saveToPrefs();
    notifyListeners();
  }

  // --- PERBAIKAN 1: Tambahkan fungsi removeAction ---
  void removeAction(String id) {
    _actions.removeWhere((action) => action.id == id);
    _saveToPrefs();
    notifyListeners();
  }

  // --- PERBAIKAN 2: Tambahkan fungsi updateAction ---
  void updateAction(String id, String newLabel, double newAmount, String newCategory, IconData newIcon) {
    final index = _actions.indexWhere((action) => action.id == id);
    if (index != -1) {
      _actions[index] = QuickAction(
        id: id,
        label: newLabel,
        amount: newAmount,
        category: newCategory,
        icon: newIcon,
      );
      notifyListeners();
      // Jika ada database, simpan perubahannya di sini juga
    }
  }

  void clearAll() {
    _actions = [];
    notifyListeners();
  }
}