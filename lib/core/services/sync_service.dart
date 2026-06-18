import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/debt/domain/entities/debt_entity.dart';
import 'package:sipeka/features/debt/data/models/debt_model.dart';
import 'package:sipeka/features/budget/domain/entities/budget_entity.dart';
import 'package:sipeka/features/budget/data/models/budget_model.dart';
import 'package:sipeka/features/wishlist/domain/entities/wishlist_entity.dart';
import 'package:sipeka/features/wishlist/data/models/wishlist_model.dart';
import 'package:sipeka/features/category/domain/entities/category_entity.dart' as models;
import 'package:sipeka/features/category/data/models/category_model.dart';
import 'package:sipeka/core/database/database_helper.dart';

class SyncService {
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
        'source': tx.source,
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
      final model = DebtModel.fromEntity(d);
      batch.set(docRef, model.toJson());
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
        source: data['source'] ?? 'Manual',
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
      return DebtModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // --- SINKRONISASI BUDGET ---
  Future<void> syncBudgets(List<Budget> budgets) async {
    if (_userId == null) return;
    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(_userId).collection('budgets');

    for (var b in budgets) {
      final model = BudgetModel.fromEntity(b);
      batch.set(collection.doc(b.id), model.toJson());
    }
    await batch.commit();
  }

  Future<List<Budget>> getBudgetsFromCloud() async {
    if (_userId == null) return [];
    final snapshot = await _firestore.collection('users').doc(_userId).collection('budgets').get();

    return snapshot.docs.map((doc) {
      return BudgetModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // --- SINKRONISASI WISHLIST ---
  Future<void> syncWishlist(List<WishlistItem> items) async {
    if (_userId == null) return;
    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(_userId).collection('wishlist');

    for (var item in items) {
      final model = WishlistModel.fromEntity(item);
      batch.set(collection.doc(item.id), model.toJson());
    }
    await batch.commit();
  }

  Future<List<WishlistItem>> getWishlistFromCloud() async {
    if (_userId == null) return [];
    final snapshot = await _firestore.collection('users').doc(_userId).collection('wishlist').get();

    return snapshot.docs.map((doc) {
      return WishlistModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // --- SINKRONISASI KATEGORI ---
  Future<void> syncCategories(List<models.Category> categories) async {
    if (_userId == null) return;
    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(_userId).collection('categories');

    for (var cat in categories) {
      final model = CategoryModel.fromEntity(cat);
      batch.set(collection.doc(cat.id), model.toJson());
    }
    await batch.commit();
  }

  // --- RESTORE KATEGORI ---
  Future<List<models.Category>> getCategoriesFromCloud() async {
    if (_userId == null) return [];
    final snapshot = await _firestore.collection('users').doc(_userId).collection('categories').get();

    return snapshot.docs.map((doc) {
      return CategoryModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Sinkronisasi semua data lokal ke Firebase Cloud sekaligus.
  Future<void> syncAllData() async {
    if (_userId == null) {
      throw Exception("User belum login");
    }

    // Ambil semua data dari SQLite lokal
    final transactionsMap = await DatabaseHelper.instance.getAllTransactions();
    final budgetsMap = await DatabaseHelper.instance.getAllBudgets();
    final debtsMap = await DatabaseHelper.instance.getAllDebts();
    final wishlistMap = await DatabaseHelper.instance.getAllWishlist();

    final List<Transaction> transactions = transactionsMap.map((e) => Transaction(
      id: e['id'], title: e['title'],
      amount: (e['amount'] as num).toDouble(),
      date: DateTime.parse(e['date']),
      type: e['type'], category: e['category'],
      wallet: e['wallet'], source: e['source'] ?? 'Manual',
    )).toList();

    final List<Budget> budgets = budgetsMap.map((e) => Budget(
      id: e['id'],
      category: e['category'],
      limit: (e['limit_amount'] as num).toDouble(),
      iconCode: e['icon_code'] ?? 0,
    )).toList();

    final List<Debt> debts = debtsMap.map((e) => Debt(
      id: e['id'], name: e['name'],
      amount: (e['amount'] as num).toDouble(),
      date: DateTime.parse(e['date']),
      type: e['type'], isPaid: e['is_paid'] == 1,
      notes: e['notes'],
    )).toList();

    final List<WishlistItem> wishlists = wishlistMap.map((e) => WishlistItem(
      id: e['id'].toString(), title: e['title'],
      targetAmount: (e['target'] as num).toDouble(),
      savedAmount: (e['collected'] as num).toDouble(),
    )).toList();

    await syncTransactions(transactions);
    await syncBudgets(budgets);
    await syncDebts(debts);
    await syncWishlist(wishlists);
  }
}
