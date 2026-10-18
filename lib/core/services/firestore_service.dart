import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Central Firestore access helper.
/// Semua koleksi data disimpan di bawah `users/{userId}/...`
class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  FirestoreService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _guestUid = 'guest_default';

  /// Inisialisasi Service saat aplikasi dimulai:
  /// Menyiapkan UID guest persisten (offline-ready) & auto-seeding
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedUid = prefs.getString('sipeka_guest_uid');
      if (savedUid == null) {
        savedUid = 'guest_${const Uuid().v4().replaceAll('-', '').substring(0, 12)}';
        await prefs.setString('sipeka_guest_uid', savedUid);
      }
      _guestUid = savedUid;

      // Coba anonymous sign-in jika belum ada sesi akun sama sekali
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
          debugPrint("FIRESTORE: Anonymous sign-in berhasil: ${_auth.currentUser?.uid}");
        } catch (e) {
          debugPrint("FIRESTORE: Anonymous sign-in skip / offline: $e");
        }
      }

      // Pastikan dompet default tersedia
      await seedDefaultWalletsIfNeeded();
    } catch (e) {
      debugPrint("FIRESTORE: Error init FirestoreService: $e");
    }
  }

  /// Mendapatkan UID user yang sedang aktif.
  /// Jika belum login akun Google, otomatis menggunakan UID anonymous atau guest device UID lokal.
  String get userId {
    final user = _auth.currentUser;
    if (user != null) return user.uid;
    return _guestUid;
  }

  /// Cek apakah user sudah login dengan akun Google (bukan guest/anonymous)
  bool get isLoggedIn => _auth.currentUser != null && !_auth.currentUser!.isAnonymous;

  /// Mendapatkan referensi koleksi di bawah user path
  CollectionReference<Map<String, dynamic>> userCollection(String collectionName) {
    return _firestore.collection('users').doc(userId).collection(collectionName);
  }

  /// Memindahkan seluruh data dari sourceUid ke targetUid (misal saat login Google)
  Future<void> migrateDataBetweenUsers(String sourceUid, String targetUid) async {
    if (sourceUid == targetUid) return;
    try {
      debugPrint("FIRESTORE: Memulai migrasi data dari $sourceUid ke $targetUid...");
      final collections = [
        'transactions', 'budgets', 'debts', 'wishlist', 
        'wishlist_history', 'wallets', 'bills', 'chat_messages'
      ];
      for (final col in collections) {
        final snapshot = await _firestore.collection('users').doc(sourceUid).collection(col).get();
        if (snapshot.docs.isEmpty) continue;
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          final targetDoc = _firestore.collection('users').doc(targetUid).collection(col).doc(doc.id);
          batch.set(targetDoc, doc.data(), SetOptions(merge: true));
        }
        await batch.commit();
      }
      debugPrint("FIRESTORE: Migrasi data berhasil selesai!");
    } catch (e) {
      debugPrint("FIRESTORE: Error migrasi data: $e");
    }
  }

  /// Seed default wallets jika koleksi wallets masih kosong
  Future<void> seedDefaultWalletsIfNeeded() async {
    try {
      final snapshot = await userCollection('wallets').limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint("FIRESTORE: Seeding default wallets...");
        await userCollection('wallets').doc('dompet').set({
          'name': 'Dompet',
          'initial_balance': 0.0,
          'icon_code': 58263,
          'color_hex': '#2972FF',
          'is_shared': false,
        });
        await userCollection('wallets').doc('ewallet').set({
          'name': 'E-Wallet',
          'initial_balance': 0.0,
          'icon_code': 57929,
          'color_hex': '#00B0FF',
          'is_shared': false,
        });
        debugPrint("FIRESTORE: Default wallets berhasil di-seed!");
      }
    } catch (e) {
      debugPrint("FIRESTORE: Error seeding wallets: $e");
    }
  }

  /// Hapus semua data user (clear all collections)
  Future<void> clearAllUserData() async {
    final collections = [
      'transactions', 'budgets', 'debts', 'wishlist', 
      'wishlist_history', 'wallets', 'bills', 'chat_messages'
    ];
    for (final name in collections) {
      final snapshot = await userCollection(name).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    // Re-seed default wallets
    invalidateWalletsCache();
    await seedDefaultWalletsIfNeeded();
    debugPrint("FIRESTORE: Semua data user berhasil dihapus.");
  }

  /// Statistik: Total income bulan ini
  Future<double> getTotalIncomeCurrentMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();
    
    final snapshot = await userCollection('transactions')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThan: endOfMonth)
        .get();
    
    return snapshot.docs.fold<double>(0.0, (total, doc) {
      final data = doc.data();
      if (data['type'] == 'Income') {
        return total + ((data['amount'] as num?)?.toDouble() ?? 0.0);
      }
      return total;
    });
  }

  /// Statistik: Total expense bulan ini
  Future<double> getTotalExpenseCurrentMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();
    
    final snapshot = await userCollection('transactions')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThan: endOfMonth)
        .get();
    
    return snapshot.docs.fold<double>(0.0, (total, doc) {
      final data = doc.data();
      if (data['type'] == 'Expense') {
        return total + ((data['amount'] as num?)?.toDouble() ?? 0.0);
      }
      return total;
    });
  }

  /// Statistik: Total hutang belum lunas
  Future<double> getTotalUnpaidDebt() async {
    final snapshot = await userCollection('debts')
        .where('isPaid', isEqualTo: false)
        .get();
    
    return snapshot.docs.fold<double>(0.0, (total, doc) {
      return total + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0);
    });
  }

  List<Map<String, dynamic>>? _cachedWallets;

  /// Invalidate cache dompet saat ada penambahan/perubahan/penghapusan
  void invalidateWalletsCache() {
    _cachedWallets = null;
  }

  /// Mendapatkan semua wallets sebagai List<Map> dengan caching in-memory super cepat
  Future<List<Map<String, dynamic>>> getAllWallets({bool forceRefresh = false}) async {
    if (_cachedWallets != null && !forceRefresh) {
      return _cachedWallets!;
    }
    final snapshot = await userCollection('wallets').get();
    _cachedWallets = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    return _cachedWallets!;
  }

  /// Mendapatkan riwayat pesan AI chat (terurut timestamp ascending)
  Future<List<Map<String, dynamic>>> getAllChatMessages() async {
    final snapshot = await userCollection('chat_messages')
        .orderBy('timestamp', descending: false)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Menyimpan pesan chat ke Firestore
  Future<void> insertChatMessage(Map<String, dynamic> data) async {
    await userCollection('chat_messages').add(data);
  }

  /// Menghapus semua riwayat pesan chat AI
  Future<void> clearChatMessages() async {
    final snapshot = await userCollection('chat_messages').get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
