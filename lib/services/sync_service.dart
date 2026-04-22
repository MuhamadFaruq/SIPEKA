/* SIPEKA - Sync Service (Disabled Temporarily)
  file ini dinonaktifkan sementara untuk menghindari error build iOS 
  akibat konflik non-modular header di Xcode 16.
*/

// import 'package:cloud_firestore/cloud_firestore.dart' as firestore; 
// import 'package:firebase_auth/firebase_auth.dart';

class SyncService {
  /* // Gunakan alias 'firestore' yang sudah kita buat di atas
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // --- SINKRONISASI TRANSAKSI ---
  Future<void> syncTransactions(List<Transaction> transactions) async {
    if (_userId == null) return;

    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(_userId).collection('transactions');
    
    for (var tx in transactions) {
      final docRef = collection.doc(tx.id);
      batch.set(docRef, {
        'title': tx.title,
        'amount': tx.amount,
        'category': tx.category,
        'wallet': tx.wallet,
        'type': tx.type,
        'date': tx.date.toIso8601String(),
      });
    }
    await batch.commit();
  }

  // --- SINKRONISASI HUTANG ---
  Future<void> syncDebts(List<Debt> debts) async {
    if (_userId == null) return;

    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(_userId).collection('debts');

    for (var d in debts) {
      final docRef = collection.doc(d.id);
      batch.set(docRef, {
        'name': d.name,
        'amount': d.amount,
        'type': d.type,
        'isPaid': d.isPaid,
        'notes': d.notes,
        'date': d.date.toIso8601String(),
        'paidDate': d.paidDate?.toIso8601String(),
      });
    }
    await batch.commit();
  }

  // --- RESTORE TRANSAKSI ---
  Future<List<Transaction>> getTransactionsFromCloud() async {
    if (_userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Transaction(
        id: doc.id,
        title: data['title'],
        amount: (data['amount'] as num).toDouble(),
        date: DateTime.parse(data['date']),
        type: data['type'],
        category: data['category'],
        wallet: data['wallet'],
      );
    }).toList();
  }

  // --- RESTORE HUTANG ---
  Future<List<Debt>> getDebtsFromCloud() async {
    if (_userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('debts')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Debt(
        id: doc.id,
        name: data['name'],
        amount: (data['amount'] as num).toDouble(),
        type: data['type'],
        isPaid: data['isPaid'] ?? false,
        notes: data['notes'],
        date: DateTime.parse(data['date']),
        paidDate: data['paidDate'] != null ? DateTime.parse(data['paidDate']) : null,
      );
    }).toList();
  }

  // --- SINKRONISASI BUDGET ---
  Future<void> syncBudgets(List<Budget> budgets) async {
    if (_userId == null) return;
    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(_userId).collection('budgets');

    for (var b in budgets) {
      batch.set(collection.doc(b.category), {
        'category': b.category,
        'limit': b.limit,
        'iconCode': b.iconCode,
      });
    }
    await batch.commit();
  }

  Future<List<Budget>> getBudgetsFromCloud() async {
    if (_userId == null) return [];
    final snapshot = await _firestore.collection('users').doc(_userId).collection('budgets').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Budget(
        id: doc.id,
        category: data['category'],
        limit: (data['limit'] as num).toDouble(),
        iconCode: data['iconCode'],
        usedAmount: 0.0,
      );
    }).toList();
  }

  // --- SINKRONISASI WISHLIST ---
  Future<void> syncWishlist(List<WishlistItem> items) async {
    if (_userId == null) return;
    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(_userId).collection('wishlist');

    for (var item in items) {
      batch.set(collection.doc(item.id), {
        'title': item.title,
        'targetamount': item.targetAmount,
        'savedamount': item.savedAmount,
        'isComplete': item.savedAmount >= item.targetAmount,  
      });
    }
    await batch.commit();
  }

  Future<List<WishlistItem>> getWishlistFromCloud() async {
    if (_userId == null) return [];
    final snapshot = await _firestore.collection('users').doc(_userId).collection('wishlist').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return WishlistItem(
        id: doc.id,
        title: data['title'],
        targetAmount: (data['targetAmount'] as num).toDouble(),
        savedAmount: (data['savedAmount'] as num).toDouble(),
      );
    }).toList();
  }

  // --- SINKRONISASI KATEGORI ---
  Future<void> syncCategories(List<models.Category> categories) async {
    if (_userId == null) return;
    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(_userId).collection('categories');

    for (var cat in categories) {
      batch.set(collection.doc(cat.id), {
        'name': cat.name,
        'type': cat.type,
        'icon': cat.icon,
        'color': cat.color,
      });
    }
    await batch.commit();
  }

  // --- RESTORE KATEGORI ---
  Future<List<models.Category>> getCategoriesFromCloud() async {
    if (_userId == null) return [];
    final snapshot = await _firestore.collection('users').doc(_userId).collection('categories').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return models.Category(
        id: doc.id,
        name: data['name'],
        type: data['type'],
        icon: data['icon'],
        color: data['color'],
      );
    }).toList();
  }
  */

  // Placeholder agar class tidak kosong dan tidak error saat dipanggil
  Future<void> syncAllData() async {
    print("Sinkronisasi Firebase dinonaktifkan sementara.");
  }
}