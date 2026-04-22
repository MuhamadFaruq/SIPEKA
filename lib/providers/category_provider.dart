import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../utils/storage.dart';
// import '../services/sync_service.dart'; // [KOMENTAR] Firebase dinonaktifkan

class CategoryProvider with ChangeNotifier {
  List<models.Category> _categories = [];
  
  // [KOMENTAR] Nonaktifkan SyncService untuk sementara
  // final SyncService _syncService = SyncService(); 
  
  List<models.Category> get categories => List.unmodifiable(_categories);

  // Helper untuk memisahkan kategori berdasarkan tipe (Income/Expense)
  List<models.Category> getCategoriesByType(String type) {
    return _categories.where((c) => c.type == type).toList();
  }

  // Ambil kategori berdasarkan ID
  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Load categories from storage (SQFlite / Local Storage)
  Future<void> loadCategories() async {
    try {
      final jsonList = await Storage.loadCategories();
      if (jsonList.isEmpty) {
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

  // --- CRUD FUNCTIONS (MURNI LOKAL) ---

  Future<void> addCategory(models.Category category) async {
    _categories.add(category);
    await _saveCategories();
    // _syncCloud(); // [KOMENTAR] Tidak sinkron ke Firebase
    notifyListeners();
  }

  Future<void> updateCategory(models.Category updatedCategory) async {
    final index = _categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index == -1) return;
    
    _categories[index] = updatedCategory;
    await _saveCategories();
    // _syncCloud(); // [KOMENTAR] Tidak sinkron ke Firebase
    notifyListeners();
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
    await _saveCategories();
    // _syncCloud(); // [KOMENTAR] Tidak sinkron ke Firebase
    notifyListeners();
  }

  // --- FUNGSI RESTORE (NONAKTIF) ---
  Future<void> restoreCategoriesFromCloud() async {
    // [KOMENTAR] Fitur cloud dimatikan sementara
    debugPrint("Fitur restore cloud sedang dinonaktifkan.");
    /*
    try {
      final List<models.Category> cloudCats = await _syncService.getCategoriesFromCloud();
      if (cloudCats.isNotEmpty) {
        _categories = cloudCats;
        await _saveCategories(); 
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Gagal restore kategori: $e");
    }
    */
  }

  // [KOMENTAR] Fungsi sinkronisasi dimatikan
  void _syncCloud() {
    /*
    _syncService.syncCategories(_categories).catchError((e) {
      debugPrint("Gagal sinkron kategori ke cloud: $e");
    });
    */
  }

  Future<void> _saveCategories() async {
    final jsonList = _categories.map((c) => c.toJson()).toList();
    await Storage.saveCategories(jsonList);
  }

  // Initialize default categories (Data awal saat aplikasi pertama diinstal)
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

  // Check if category is used in transactions
  bool isCategoryUsed(String categoryId) {
    // Logika ini biasanya mengecek ke TransactionProvider
    return false;
  }
}