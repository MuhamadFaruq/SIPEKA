import 'package:flutter/foundation.dart';
import 'package:sipeka/core/services/firestore_service.dart';
import '../models/wishlist_model.dart';
import '../models/wishlist_history_model.dart';

abstract class WishlistDataSource {
  Future<List<WishlistModel>> getWishlist();
  Future<String> insertWishlist(WishlistModel item);
  Future<void> updateSavings(String id, double newAmount);
  Future<void> deleteWishlist(String id);
  Future<void> clearWishlists();
  Future<void> insertWishlistHistory(WishlistHistoryModel history);
  Future<List<WishlistHistoryModel>> getHistoryByWishlistId(String wishlistId);
  Future<List<WishlistHistoryModel>> getAllWishlistHistory();
}

class WishlistFirestoreDataSource implements WishlistDataSource {
  final FirestoreService _firestoreService;

  WishlistFirestoreDataSource([FirestoreService? firestoreService])
      : _firestoreService = firestoreService ?? FirestoreService.instance;

  @override
  Future<List<WishlistModel>> getWishlist() async {
    final snapshot = await _firestoreService.userCollection('wishlist').get();
    debugPrint("FIRESTORE: getWishlist => ${snapshot.docs.length} docs");
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return WishlistModel(
        id: doc.id,
        title: data['title'] as String? ?? '',
        targetAmount: (data['targetAmount'] as num?)?.toDouble() ??
            (data['target'] as num?)?.toDouble() ??
            0.0,
        savedAmount: (data['savedAmount'] as num?)?.toDouble() ??
            (data['collected'] as num?)?.toDouble() ??
            0.0,
      );
    }).toList();
  }

  @override
  Future<String> insertWishlist(WishlistModel item) async {
    // Gunakan auto-generated ID dari Firestore
    final docRef = await _firestoreService.userCollection('wishlist').add({
      'title': item.title,
      'targetAmount': item.targetAmount,
      'savedAmount': item.savedAmount,
      'icon_code': 58419,
    });
    debugPrint("FIRESTORE: insertWishlist OK, id=${docRef.id}");
    return docRef.id;
  }

  @override
  Future<void> updateSavings(String id, double newAmount) async {
    await _firestoreService.userCollection('wishlist').doc(id).update({
      'savedAmount': newAmount,
    });
    debugPrint("FIRESTORE: updateSavings OK, id=$id, amount=$newAmount");
  }

  @override
  Future<void> deleteWishlist(String id) async {
    // Hapus juga history yang terkait
    final historySnapshot = await _firestoreService
        .userCollection('wishlist_history')
        .where('wishlist_id', isEqualTo: id)
        .get();
    for (final doc in historySnapshot.docs) {
      await doc.reference.delete();
    }
    await _firestoreService.userCollection('wishlist').doc(id).delete();
    debugPrint("FIRESTORE: deleteWishlist OK, id=$id");
  }

  @override
  Future<void> clearWishlists() async {
    final wishlistSnapshot = await _firestoreService.userCollection('wishlist').get();
    for (final doc in wishlistSnapshot.docs) {
      await doc.reference.delete();
    }
    final historySnapshot = await _firestoreService.userCollection('wishlist_history').get();
    for (final doc in historySnapshot.docs) {
      await doc.reference.delete();
    }
    debugPrint("FIRESTORE: clearWishlists OK");
  }

  @override
  Future<void> insertWishlistHistory(WishlistHistoryModel history) async {
    await _firestoreService
        .userCollection('wishlist_history')
        .doc(history.id)
        .set(history.toMap());
    debugPrint("FIRESTORE: insertWishlistHistory OK, id=${history.id}");
  }

  @override
  Future<List<WishlistHistoryModel>> getHistoryByWishlistId(String wishlistId) async {
    final snapshot = await _firestoreService
        .userCollection('wishlist_history')
        .where('wishlist_id', isEqualTo: wishlistId)
        .get();
    final list = snapshot.docs.map((doc) {
      return WishlistHistoryModel.fromMap({'id': doc.id, ...doc.data()});
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<WishlistHistoryModel>> getAllWishlistHistory() async {
    final snapshot = await _firestoreService
        .userCollection('wishlist_history')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return WishlistHistoryModel.fromMap({'id': doc.id, ...doc.data()});
    }).toList();
  }
}
