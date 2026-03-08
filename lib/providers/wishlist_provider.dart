import 'package:flutter/material.dart';
import '../models/wishlist_model.dart';
import '../utils/database_helper.dart';

class WishlistProvider with ChangeNotifier {
  List<WishlistItem> _items = [];

  List<WishlistItem> get items => _items;

  double get totalSaved => _items.fold(0, (sum, item) => sum + item.savedAmount);
  double get totalTarget => _items.fold(0, (sum, item) => sum + item.targetAmount);

  // --- FUNGSI AMBIL DATA DARI DATABASE ---
  Future<void> fetchAndSetWishlist() async {
    final dataList = await DatabaseHelper.instance.getAllWishlist();
    _items = dataList.map((item) => WishlistItem(
      id: item['id'].toString(), // SQLite id biasanya int, kita convert ke string
      title: item['title'],
      targetAmount: item['target'],
      savedAmount: item['collected'],
    )).toList();
    notifyListeners();
  }

  // --- FUNGSI TAMBAH (SINKRON SQLITE) ---
  Future<void> addWishlist(WishlistItem item) async {
    _items.add(item);
    notifyListeners();

    await DatabaseHelper.instance.insertWishlist({
      'title': item.title,
      'target': item.targetAmount,
      'collected': item.savedAmount,
      'icon_code': 58419, // Default icon stars
    });
    
    // Refresh data agar mendapatkan ID asli dari database
    await fetchAndSetWishlist();
  }

  // --- FUNGSI NABUNG (SINKRON SQLITE) ---
  Future<void> addSavings(String id, double amount) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].savedAmount += amount;
      notifyListeners();

      // Update di SQLite
      await DatabaseHelper.instance.updateWishlist(int.parse(id), {
        'collected': _items[index].savedAmount,
      });
    }
  }

  // --- FUNGSI HAPUS (SINKRON SQLITE) ---
  Future<void> deleteWishlist(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    
    await DatabaseHelper.instance.deleteWishlist(int.parse(id));
  }

  // --- FUNGSI RESET UNTUK SETTINGS ---
  void clearAllData() {
    _items = [];
    notifyListeners();
  }
}