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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        source TEXT
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
        type TEXT,
        is_paid INTEGER DEFAULT 0,
        paid_date TEXT,
        notes TEXT 
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Logika upgrade ke versi 2 (Hutang/Debts)
      await db.execute('DROP TABLE IF EXISTS debts');
      await db.execute('''
        CREATE TABLE debts (
          id TEXT PRIMARY KEY, name TEXT, amount REAL, date TEXT, 
          type TEXT, is_paid INTEGER DEFAULT 0, paid_date TEXT, notes TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      // LOGIKA UPGRADE KE VERSI 3: Menambah kolom source
      await db.execute("ALTER TABLE transactions ADD COLUMN source TEXT DEFAULT 'Manual'");
      print("DATABASE: Berhasil Upgrade ke Versi 3 - Kolom Source Ditambahkan");
    }
  }

  // --- CRUD TRANSAKSI ---
  // --- CRUD TRANSAKSI ---
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.insert('transactions', row);
    } catch (e) {
      print("Error Database: $e");
      return -1; // Kembalikan -1 jika gagal
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD BUDGET ---
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

  Future<int> clearBudgetTable() async {
    final db = await instance.database;
    return await db.delete('budgets'); // Pastikan nama tabelnya 'budgets'
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

  Future<int> clearDebtTable() async {
    final db = await instance.database;
    // Ganti 'debts' dengan nama tabel hutangmu jika berbeda
    return await db.delete('debts'); 
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

  Future<int> clearWishlistTable() async {
    final db = await instance.database;
    return await db.delete('wishlist'); // Sesuaikan nama tabel wishlist-mu
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