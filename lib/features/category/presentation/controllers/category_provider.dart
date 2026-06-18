import 'package:flutter/foundation.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/repositories/category_repository_impl.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryRepository repository;

  List<CategoryEntity> _categories = [];
  
  List<CategoryEntity> get categories => List.unmodifiable(_categories);

  CategoryProvider({CategoryRepository? repository})
      : repository = repository ?? CategoryRepositoryImpl();

  List<CategoryEntity> getCategoriesByType(String type) {
    return _categories.where((c) => c.type == type).toList();
  }

  CategoryEntity? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadCategories() async {
    try {
      final list = await repository.getCategories();
      if (list.isEmpty) {
        await _initializeDefaultCategories();
      } else {
        _categories = list;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      await _initializeDefaultCategories();
    }
  }

  Future<void> addCategory(CategoryEntity category) async {
    _categories.add(category);
    await repository.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> updateCategory(CategoryEntity updatedCategory) async {
    final index = _categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index == -1) return;
    
    _categories[index] = updatedCategory;
    await repository.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
    await repository.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> _initializeDefaultCategories() async {
    _categories = [
      CategoryEntity(
        id: 'cat_exp_makan',
        name: 'Makan',
        type: 'expense',
        icon: 'makan',
        color: 0xFFFF6B6B,
      ),
      CategoryEntity(
        id: 'cat_exp_minum',
        name: 'Minum',
        type: 'expense',
        icon: 'minum',
        color: 0xFFFFA500,
      ),
      CategoryEntity(
        id: 'cat_exp_bensin',
        name: 'Bensin',
        type: 'expense',
        icon: 'bensin',
        color: 0xFFFFD700,
      ),
      CategoryEntity(
        id: 'cat_exp_parkir',
        name: 'Parkir',
        type: 'expense',
        icon: 'parkir',
        color: 0xFF4ECDC4,
      ),
      CategoryEntity(
        id: 'cat_exp_belanja',
        name: 'Belanja',
        type: 'expense',
        icon: 'belanja',
        color: 0xFF95E1D3,
      ),
      CategoryEntity(
        id: 'cat_inc_gaji',
        name: 'Gaji',
        type: 'income',
        icon: 'gaji',
        color: 0xFF4ECDC4,
      ),
      CategoryEntity(
        id: 'cat_inc_bonus',
        name: 'Bonus',
        type: 'income',
        icon: 'bonus',
        color: 0xFF95E1D3,
      ),
      CategoryEntity(
        id: 'cat_inc_lainnya',
        name: 'Lainnya',
        type: 'income',
        icon: 'lainnya',
        color: 0xFF2972FF,
      ),
    ];
    await repository.saveCategories(_categories);
  }

  bool isCategoryUsed(String categoryId) {
    return false;
  }
}
