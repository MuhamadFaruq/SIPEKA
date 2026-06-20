import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sipeka.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint("DATABASE: Path => $path");

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    debugPrint("DATABASE: Membuat tabel baru (onCreate v$version)...");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        wallet TEXT NOT NULL DEFAULT 'Dompet',
        source TEXT NOT NULL DEFAULT 'Manual'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        icon_code INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target REAL NOT NULL DEFAULT 0,
        collected REAL NOT NULL DEFAULT 0,
        icon_code INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        paid_date TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    debugPrint("DATABASE: Semua tabel berhasil dibuat!");
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint("DATABASE: Meng-upgrade database dari v$oldVersion ke v$newVersion...");
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT NOT NULL,
          is_user INTEGER NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
      debugPrint("DATABASE: Tabel chat_messages berhasil ditambahkan di upgrade v2!");
    }
  }

  // --- CRUD TRANSAKSI ---
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await database;
    try {
      final result = await db.insert(
        'transactions',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("DATABASE: insertTransaction OK, result=$result, id=${row['id']}");
      return result;
    } catch (e) {
      debugPrint("DATABASE: insertTransaction ERROR: $e | row=$row");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    debugPrint("DATABASE: getAllTransactions => ${result.length} rows");
    return result;
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD BUDGET ---
  Future<int> insertBudget(Map<String, dynamic> row) async {
    final db = await database;
    try {
      final result = await db.insert(
        'budgets',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("DATABASE: insertBudget OK, result=$result, id=${row['id']}");
      return result;
    } catch (e) {
      debugPrint("DATABASE: insertBudget ERROR: $e | row=$row");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    final db = await database;
    final result = await db.query('budgets');
    debugPrint("DATABASE: getAllBudgets => ${result.length} rows");
    return result;
  }

  Future<int> updateBudget(String id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('budgets', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearBudgetTable() async {
    final db = await database;
    return await db.delete('budgets');
  }

  // --- CRUD HUTANG ---
  Future<int> insertDebt(Map<String, dynamic> row) async {
    final db = await database;
    try {
      final result = await db.insert(
        'debts',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("DATABASE: insertDebt OK, result=$result, id=${row['id']}");
      return result;
    } catch (e) {
      debugPrint("DATABASE: insertDebt ERROR: $e | row=$row");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllDebts() async {
    final db = await database;
    final result = await db.query('debts', orderBy: 'date DESC');
    debugPrint("DATABASE: getAllDebts => ${result.length} rows");
    return result;
  }

  Future<int> updateDebt(String id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('debts', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDebt(String id) async {
    final db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearDebtTable() async {
    final db = await database;
    return await db.delete('debts');
  }

  // --- CRUD WISHLIST ---
  Future<int> insertWishlist(Map<String, dynamic> row) async {
    final db = await database;
    // Hapus id dari row karena AUTOINCREMENT
    final rowWithoutId = Map<String, dynamic>.from(row)..remove('id');
    try {
      final result = await db.insert('wishlist', rowWithoutId);
      debugPrint("DATABASE: insertWishlist OK, result=$result");
      return result;
    } catch (e) {
      debugPrint("DATABASE: insertWishlist ERROR: $e | row=$rowWithoutId");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllWishlist() async {
    final db = await database;
    final result = await db.query('wishlist');
    debugPrint("DATABASE: getAllWishlist => ${result.length} rows");
    return result;
  }

  Future<int> updateWishlist(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('wishlist', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteWishlist(int id) async {
    final db = await database;
    return await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearWishlistTable() async {
    final db = await database;
    return await db.delete('wishlist');
  }

  // --- UTILITY ---
  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('wishlist');
    await db.delete('debts');
    await db.delete('chat_messages');
    debugPrint("DATABASE: Semua tabel sudah dibersihkan.");
  }

  // --- CRUD CHAT MESSAGES ---
  Future<int> insertChatMessage(Map<String, dynamic> row) async {
    final db = await database;
    try {
      final result = await db.insert('chat_messages', row);
      debugPrint("DATABASE: insertChatMessage OK, result=$result");
      return result;
    } catch (e) {
      debugPrint("DATABASE: insertChatMessage ERROR: $e | row=$row");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllChatMessages() async {
    final db = await database;
    final result = await db.query('chat_messages', orderBy: 'id ASC');
    debugPrint("DATABASE: getAllChatMessages => ${result.length} rows");
    return result;
  }

  Future<int> clearChatMessagesTable() async {
    final db = await database;
    return await db.delete('chat_messages');
  }

  Future close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}