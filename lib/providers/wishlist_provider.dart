import 'package:flutter/material.dart';
import '../models/wishlist_model.dart';


class WishlistProvider with ChangeNotifier {
  // Data Dummy sesuai Figma kamu
  final List<WishlistItem> _items = [
    WishlistItem(id: '1', title: 'Sepatu Running', targetAmount: 1500000, savedAmount: 900000),
    WishlistItem(id: '2', title: 'Liburan Ke Bali', targetAmount: 5000000, savedAmount: 1200000),
    WishlistItem(id: '3', title: 'HP iPhone', targetAmount: 10000000, savedAmount: 110000),
  ];

  List<WishlistItem> get items => _items;

  double get totalSaved => _items.fold(0, (sum, item) => sum + item.savedAmount);
  double get totalTarget => _items.fold(0, (sum, item) => sum + item.targetAmount);

  void addWishlist(WishlistItem item) {
    _items.add(item);
    notifyListeners();
  }

  void addSavings(String id, double amount) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].savedAmount += amount;
      notifyListeners();
    }
  }

  void deleteWishlist(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}