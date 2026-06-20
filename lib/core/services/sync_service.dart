import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
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

    final collection = _firestore.collection('users').doc(_userId).collection('transactions');
    const int batchLimit = 500;

    for (var i = 0; i < transactions.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = transactions.sublist(
        i,
        i + batchLimit > transactions.length ? transactions.length : i + batchLimit,
      );

      for (var tx in chunk) {
        final docRef = collection.doc(tx.id);
        batch.set(docRef, {
          'title': tx.title,
          'amount': tx.amount,
          'category': tx.category,
          'wallet': tx.wallet,
          'type': tx.type.dbValue,
          'date': tx.date.toIso8601String(),
          'source': tx.source,
        });
      }
      await batch.commit();
    }
  }

  // --- SINKRONISASI HUTANG ---
  Future<void> syncDebts(List<Debt> debts) async {
    if (_userId == null) return;

    final collection = _firestore.collection('users').doc(_userId).collection('debts');
    const int batchLimit = 500;

    for (var i = 0; i < debts.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = debts.sublist(
        i,
        i + batchLimit > debts.length ? debts.length : i + batchLimit,
      );

      for (var d in chunk) {
        final docRef = collection.doc(d.id);
        final model = DebtModel.fromEntity(d);
        batch.set(docRef, model.toJson());
      }
      await batch.commit();
    }
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
        type: TransactionType.fromString(data['type'] as String?),
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

    final collection = _firestore.collection('users').doc(_userId).collection('budgets');
    const int batchLimit = 500;

    for (var i = 0; i < budgets.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = budgets.sublist(
        i,
        i + batchLimit > budgets.length ? budgets.length : i + batchLimit,
      );

      for (var b in chunk) {
        final model = BudgetModel.fromEntity(b);
        batch.set(collection.doc(b.id), model.toJson());
      }
      await batch.commit();
    }
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

    final collection = _firestore.collection('users').doc(_userId).collection('wishlist');
    const int batchLimit = 500;

    for (var i = 0; i < items.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = items.sublist(
        i,
        i + batchLimit > items.length ? items.length : i + batchLimit,
      );

      for (var item in chunk) {
        final model = WishlistModel.fromEntity(item);
        batch.set(collection.doc(item.id), model.toJson());
      }
      await batch.commit();
    }
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
    final collection = _firestore.collection('users').doc(_userId).collection('categories');
    const int batchLimit = 500;

    for (var i = 0; i < categories.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = categories.sublist(
        i,
        i + batchLimit > categories.length ? categories.length : i + batchLimit,
      );

      for (var cat in chunk) {
        final model = CategoryModel.fromEntity(cat);
        batch.set(collection.doc(cat.id), model.toJson());
      }
      await batch.commit();
    }
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
      id: e['id'] as String,
      title: e['title'] as String,
      amount: (e['amount'] as num).toDouble(),
      date: DateTime.parse(e['date'] as String),
      type: TransactionType.fromString(e['type'] as String?),
      category: e['category'] as String,
      wallet: e['wallet'] as String,
      source: (e['source'] as String?) ?? 'Manual',
    )).toList();

    final List<Budget> budgets = budgetsMap.map((e) => Budget(
      id: e['id'],
      category: e['category'],
      limit: (e['limit_amount'] as num).toDouble(),
      iconCode: e['icon_code'] ?? 0,
    )).toList();

    final List<Debt> debts = debtsMap.map((e) => Debt(
      id: e['id'] as String,
      name: e['name'] as String,
      amount: (e['amount'] as num).toDouble(),
      date: DateTime.parse(e['date'] as String),
      type: e['type'] as String,
      isPaid: e['is_paid'] == 1,
      notes: e['notes'] as String?,
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

    // Sync wallets to Cloud
    final walletsMap = await DatabaseHelper.instance.getAllWallets();
    final walletsCollection = _firestore.collection('users').doc(_userId).collection('wallets');
    for (var w in walletsMap) {
      await walletsCollection.doc(w['id']).set({
        'name': w['name'],
        'initial_balance': w['initial_balance'],
        'icon_code': w['icon_code'],
        'color_hex': w['color_hex'],
      });
    }

    // Sync bills to Cloud
    final billsMap = await DatabaseHelper.instance.getAllBills();
    final billsCollection = _firestore.collection('users').doc(_userId).collection('bills');
    for (var b in billsMap) {
      await billsCollection.doc(b['id']).set({
        'title': b['title'],
        'amount': b['amount'],
        'type': b['type'],
        'category': b['category'],
        'wallet': b['wallet'],
        'frequency': b['frequency'],
        'start_date': b['start_date'],
        'last_executed_date': b['last_executed_date'],
        'next_execution_date': b['next_execution_date'],
        'is_active': b['is_active'],
        'remind_me': b['remind_me'],
      });
    }
  }

  /// Memulihkan semua data dari Firebase Cloud ke SQLite lokal.
  Future<void> restoreAllData() async {
    if (_userId == null) {
      throw Exception("User belum login");
    }

    // 1. Ambil data dari cloud
    final transactions = await getTransactionsFromCloud();
    final budgets = await getBudgetsFromCloud();
    final debts = await getDebtsFromCloud();
    final wishlist = await getWishlistFromCloud();
    final walletsSnapshot = await _firestore.collection('users').doc(_userId).collection('wallets').get();
    final billsSnapshot = await _firestore.collection('users').doc(_userId).collection('bills').get();

    final db = await DatabaseHelper.instance.database;

    // 2. Jalankan semua pembersihan dan penyimpanan dalam satu SQLite transaction
    await db.transaction((txn) async {
      // Bersihkan semua tabel terlebih dahulu
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('wishlist');
      await txn.delete('debts');
      await txn.delete('chat_messages');
      await txn.delete('wallets');
      await txn.delete('bills');

      // Restore wallets
      if (walletsSnapshot.docs.isEmpty) {
        // Seed default wallets if cloud is empty
        await txn.insert('wallets', {
          'id': 'dompet',
          'name': 'Dompet',
          'initial_balance': 0.0,
          'icon_code': 58263,
          'color_hex': '#2972FF'
        });
        await txn.insert('wallets', {
          'id': 'ewallet',
          'name': 'E-Wallet',
          'initial_balance': 0.0,
          'icon_code': 57929,
          'color_hex': '#00B0FF'
        });
      } else {
        for (var doc in walletsSnapshot.docs) {
          final data = doc.data();
          await txn.insert('wallets', {
            'id': doc.id,
            'name': data['name'] ?? '',
            'initial_balance': (data['initial_balance'] as num?)?.toDouble() ?? 0.0,
            'icon_code': data['icon_code'] ?? 0,
            'color_hex': data['color_hex'] ?? '#007AFF',
          });
        }
      }

      // 3. Masukkan transaksi ke SQLite lokal
      for (var tx in transactions) {
        await txn.insert(
          'transactions',
          {
            'id': tx.id,
            'title': tx.title,
            'amount': tx.amount,
            'date': tx.date.toIso8601String(),
            'type': tx.type.dbValue,
            'category': tx.category,
            'wallet': tx.wallet,
            'source': tx.source,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. Masukkan budgets ke SQLite lokal
      for (var b in budgets) {
        await txn.insert(
          'budgets',
          {
            'id': b.id,
            'category': b.category,
            'limit_amount': b.limit,
            'icon_code': b.iconCode,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 5. Masukkan debts ke SQLite lokal
      for (var d in debts) {
        await txn.insert(
          'debts',
          {
            'id': d.id,
            'name': d.name,
            'amount': d.amount,
            'date': d.date.toIso8601String(),
            'type': d.type,
            'is_paid': d.isPaid ? 1 : 0,
            'paid_date': d.paidDate?.toIso8601String(),
            'notes': d.notes,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 6. Masukkan wishlist ke SQLite lokal
      for (var w in wishlist) {
        await txn.insert(
          'wishlist',
          {
            'title': w.title,
            'target': w.targetAmount,
            'collected': w.savedAmount,
            'icon_code': 0, // default
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 7. Masukkan bills ke SQLite lokal
      for (var doc in billsSnapshot.docs) {
        final data = doc.data();
        await txn.insert(
          'bills',
          {
            'id': doc.id,
            'title': data['title'] ?? '',
            'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
            'type': data['type'] ?? 'Expense',
            'category': data['category'] ?? '',
            'wallet': data['wallet'] ?? '',
            'frequency': data['frequency'] ?? 'monthly',
            'start_date': data['start_date'] ?? '',
            'last_executed_date': data['last_executed_date'],
            'next_execution_date': data['next_execution_date'] ?? '',
            'is_active': data['is_active'] ?? 1,
            'remind_me': data['remind_me'] ?? 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
