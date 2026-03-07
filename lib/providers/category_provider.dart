import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../utils/storage.dart';

class CategoryProvider with ChangeNotifier {
  List<models.Category> _categories = [];

  List<models.Category> get categories => List.unmodifiable(_categories);

  // Get categories by type
  List<models.Category> getCategoriesByType(String type) {
    return _categories.where((c) => c.type == type).toList();
  }

  // Get category by ID
  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Load categories from storage
  Future<void> loadCategories() async {
    try {
      final jsonList = await Storage.loadCategories();
      if (jsonList.isEmpty) {
        // Initialize with default categories
        await _initializeDefaultCategories();
      } else {
        _categories = jsonList.map((json) => models.Category.fromJson(json)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      await _initializeDefaultCategories();
    }
  }

  // Initialize default categories
  Future<void> _initializeDefaultCategories() async {
    _categories = [
      // Expense Categories
      models.Category(
        id: 'cat_exp_makan',
        name: 'Makan',
        type: 'expense',
        icon: 'makan',
        color: 0xFFFF6B6B,
      ),
      models.Category(
        id: 'cat_exp_minum',
        name: 'Minum',
        type: 'expense',
        icon: 'minum',
        color: 0xFFFFA500,
      ),
      models.Category(
        id: 'cat_exp_bensin',
        name: 'Bensin',
        type: 'expense',
        icon: 'bensin',
        color: 0xFFFFD700,
      ),
      models.Category(
        id: 'cat_exp_parkir',
        name: 'Parkir',
        type: 'expense',
        icon: 'parkir',
        color: 0xFF4ECDC4,
      ),
      models.Category(
        id: 'cat_exp_belanja',
        name: 'Belanja',
        type: 'expense',
        icon: 'belanja',
        color: 0xFF95E1D3,
      ),
      // Income Categories
      models.Category(
        id: 'cat_inc_gaji',
        name: 'Gaji',
        type: 'income',
        icon: 'gaji',
        color: 0xFF4ECDC4,
      ),
      models.Category(
        id: 'cat_inc_bonus',
        name: 'Bonus',
        type: 'income',
        icon: 'bonus',
        color: 0xFF95E1D3,
      ),
      models.Category(
        id: 'cat_inc_lainnya',
        name: 'Lainnya',
        type: 'income',
        icon: 'lainnya',
        color: 0xFF2972FF,
      ),
    ];
    await _saveCategories();
  }

  // Add category
  Future<void> addCategory(models.Category category) async {
    _categories.add(category);
    await _saveCategories();
    notifyListeners();
  }

  // Update category
  Future<void> updateCategory(models.Category updatedCategory) async {
    final index = _categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index == -1) return;
    
    _categories[index] = updatedCategory;
    await _saveCategories();
    notifyListeners();
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
    await _saveCategories();
    notifyListeners();
  }

  // Check if category is used in transactions
  bool isCategoryUsed(String categoryId) {
    // This will be checked in the UI layer by querying TransactionProvider
    // For now, return false to allow deletion
    return false;
  }

  // Save categories to storage
  Future<void> _saveCategories() async {
    final jsonList = _categories.map((c) => c.toJson()).toList();
    await Storage.saveCategories(jsonList);
  }
}

