import 'package:flutter/material.dart';
import '../models/wishlist_model.dart';
import '../utils/database_helper.dart';
// import '../services/sync_service.dart'; // DIKOMENTARI: Mengistirahatkan Firebase

class WishlistProvider with ChangeNotifier {
  List<WishlistItem> _items = [];
  
  // final SyncService _syncService = SyncService(); // DIKOMENTARI: Mengistirahatkan Firebase

  List<WishlistItem> get items => _items;

  // Logika perhitungan total saldo tabungan impian
  double get totalSaved => _items.fold(0, (sum, item) => sum + item.savedAmount);
  double get totalTarget => _items.fold(0, (sum, item) => sum + item.targetAmount);

  // Ambil data dari Database Lokal (SQFlite)
  Future<void> fetchAndSetWishlist() async {
    try {
      final dataList = await DatabaseHelper.instance.getAllWishlist();
      _items = dataList.map((item) => WishlistItem(
        id: item['id'].toString(), 
        title: item['title'],
        targetAmount: (item['target'] as num).toDouble(),
        savedAmount: (item['collected'] as num).toDouble(),
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error saat fetch wishlist: $e");
    }
  }

  // --- CRUD FUNCTIONS (MURNI LOKAL) ---

  Future<void> addWishlist(WishlistItem item) async {
    // Tambah ke database dulu
    await DatabaseHelper.instance.insertWishlist({
      'title': item.title,
      'target': item.targetAmount,
      'collected': item.savedAmount,
      'icon_code': 58419, // Default icon
    });
    
    // Refresh data dari database agar ID-nya sinkron
    await fetchAndSetWishlist();
    
    // _syncCloud(); // DIKOMENTARI: Mengistirahatkan Firebase
  }

  Future<void> addSavings(String id, double amount) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      double newAmount = _items[index].savedAmount + amount;

      // Update di Database lokal
      await DatabaseHelper.instance.updateWishlist(int.parse(id), {
        'collected': newAmount,
      });

      // Update state lokal agar UI langsung berubah (Optimistic Update)
      _items[index].savedAmount = newAmount;
      notifyListeners();

      // _syncCloud(); // DIKOMENTARI: Mengistirahatkan Firebase
    }
  }

  Future<void> deleteWishlist(String id) async {
    // Hapus di database
    await DatabaseHelper.instance.deleteWishlist(int.parse(id));
    
    // Update UI
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    
    // _syncCloud(); // DIKOMENTARI: Mengistirahatkan Firebase
  }

  // --- FUNGSI RESTORE DI-NONAKTIFKAN SEMENTARA ---
  Future<void> restoreWishlistFromCloud() async {
    debugPrint("Fitur Cloud Restore sedang dinonaktifkan sementara.");
    /* try {
      final List<WishlistItem> cloudItems = await _syncService.getWishlistFromCloud();
      // ... logika restore ...
    } catch (e) {
      debugPrint("Gagal restore wishlist: $e");
    }
    */
  }

  // DIKOMENTARI: Mengistirahatkan Firebase
  /*
  void _syncCloud() {
    _syncService.syncWishlist(_items).catchError((e) {
      debugPrint("Gagal sinkron wishlist ke cloud: $e");
    });
  }
  */

  Future<void> clearAllData() async {
    await DatabaseHelper.instance.clearWishlistTable(); // Pastikan fungsi ini ada di DatabaseHelper
    _items = [];
    notifyListeners();
  }
}