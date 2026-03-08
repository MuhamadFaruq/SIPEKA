import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        date TEXT,
        type TEXT,
        category TEXT,
        wallet TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category TEXT,
        limit_amount REAL,
        icon_code INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE wishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        target REAL,
        collected REAL,
        icon_code INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        name TEXT,
        amount REAL,
        date TEXT,
        type TEXT
      )
    ''');
  }

  // --- CRUD TRANSAKSI ---
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD ANGGARAN ---
  Future<int> insertBudget(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('budgets', row);
  }

  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    final db = await instance.database;
    return await db.query('budgets');
  }

  Future<int> updateBudget(String id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('budgets', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBudget(String id) async {
    final db = await instance.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD HUTANG ---
  Future<int> insertDebt(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('debts', row);
  }

  Future<List<Map<String, dynamic>>> getAllDebts() async {
    final db = await instance.database;
    return await db.query('debts', orderBy: 'date DESC');
  }

  Future<int> updateDebt(String id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('debts', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDebt(String id) async {
    final db = await instance.database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD WISHLIST ---
  Future<int> insertWishlist(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('wishlist', row);
  }

  Future<List<Map<String, dynamic>>> getAllWishlist() async {
    final db = await instance.database;
    return await db.query('wishlist');
  }

  Future<int> updateWishlist(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('wishlist', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteWishlist(int id) async {
    final db = await instance.database;
    return await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }

  // --- UTILITY ---
  Future<void> clearAllTables() async {
    final db = await instance.database;
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('wishlist');
    await db.delete('debts');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}