import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transaction_model.dart';
import '../utils/ocr_helper.dart';
import '../utils/database_helper.dart';
import '../utils/database_helper.dart';
// import '../services/sync_service.dart'; // Dinonaktifkan sementara

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  
  // SyncService dinonaktifkan sementara untuk menghindari error Firebase
  // final SyncService _syncService = SyncService(); 

  List<Transaction> get transactions {
    return [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
  }

  final TextEditingController nominalController = TextEditingController();

  // --- FETCH DATA (LOKAL) ---
  Future<void> fetchAndSetTransactions() async {
    try {
      final dataList = await DatabaseHelper.instance.getAllTransactions();
      _transactions = dataList.map((item) => Transaction(
        id: item['id'],
        title: item['title'],
        amount: item['amount'],
        date: DateTime.parse(item['date']),
        type: item['type'],
        category: item['category'],
        wallet: item['wallet'],
        source: item['source'] ?? 'Manual',
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error Fetching Data: $e");
    }
  }

  // --- CRUD FUNCTIONS (MURNI LOKAL) ---

  // Ubah dari Future<void> menjadi Future<bool>
Future<bool> addTransaction(Transaction tx) async {
    // 1. Update List di Memori (Optimistic Update)
    _transactions.insert(0, tx); 
    notifyListeners();

    // 2. Simpan ke Database Lokal
    try {
      await DatabaseHelper.instance.insertTransaction({
        'id': tx.id,
        'title': tx.title,
        'amount': tx.amount,
        'date': tx.date.toIso8601String(),
        'type': tx.type,
        'category': tx.category,
        'wallet': tx.wallet,
        'source': tx.source, 
      });
      debugPrint("Berhasil simpan transaksi: ${tx.title}");
      return true; // <--- Kembalikan true jika sukses
    } catch (e) {
      debugPrint("Gagal simpan transaksi: $e");
      
      // Rollback jika gagal
      _transactions.remove(tx);
      notifyListeners();
      return false; // <--- Kembalikan false jika gagal
    }
  }

  Future<void> deleteTransaction(String id) async {
    // 1. Hapus dari memori & Lokal
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
    
    try {
      await DatabaseHelper.instance.deleteTransaction(id);
    } catch (e) {
      debugPrint("Gagal hapus lokal: $e");
    }

    // 2. Sync Cloud dinonaktifkan
    /*
    _syncService.syncTransactions(_transactions).catchError((e) {
      debugPrint("Gagal Sinkron Hapus Cloud: $e");
    });
    */
  }

  // --- RESTORE DATA (DINONAKTIFKAN) ---
  Future<void> restoreFromCloud() async {
    debugPrint("Fitur Restore Cloud dinonaktifkan sementara.");
    /*
    try {
      List<Transaction> cloudData = await _syncService.getTransactionsFromCloud();
      // ... logika restore ...
    } catch (e) {
      rethrow;
    }
    */
  }

  // --- FUNGSI SCAN NOTA (ML KIT) ---
  // Fitur ini tetap aktif karena tidak bergantung pada Firebase Auth/Firestore
  Future<double?> scanReceipt() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) return null;

      double? detectedTotal = await OCRHelper.extractTotal(pickedFile.path);
      if (detectedTotal != null) {
        nominalController.text = detectedTotal.toInt().toString();
        notifyListeners();
      }
      return detectedTotal;
    } catch (e) {
      debugPrint("Error scanning: $e");
      return null;
    }
  }

  // --- GETTER SALDO ---
  double get dompetBalance => _calculateBalance('Dompet');
  double get ewalletBalance => _calculateBalance('E-Wallet');

  double _calculateBalance(String walletType) {
    var filtered = _transactions.where((tx) => tx.wallet == walletType);
    double income = filtered.where((tx) => tx.type == 'Pemasukan' || tx.type == 'Income').fold(0, (sum, item) => sum + item.amount);
    double expense = filtered.where((tx) => tx.type == 'Pengeluaran' || tx.type == 'Expense').fold(0, (sum, item) => sum + item.amount);
    return income - expense;
  }

  Future<void> clearAllData() async {
    _transactions = [];
    notifyListeners();
    await DatabaseHelper.instance.clearAllTables(); 
  }

  Future<void> loadTransactions() async {
    await fetchAndSetTransactions();
  }

  @override
  void dispose() {
    nominalController.dispose();
    super.dispose();
  }

  List<Transaction> getFilteredTransactions({
    required String query,
    DateTimeRange? dateRange,
    String category = 'Semua',
  }) {
    return _transactions.where((tx) {
      // 1. Filter Kata Kunci (Judul)
      final matchesQuery = tx.title.toLowerCase().contains(query.toLowerCase());

      // 2. Filter Rentang Tanggal
      bool matchesDate = true;
      if (dateRange != null) {
        // Kita hilangkan jam/menit/detik agar perbandingannya murni tanggal
        DateTime startDate = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
        DateTime endDate = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
        matchesDate = tx.date.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
                      tx.date.isBefore(endDate);
      }

      // 3. Filter Kategori
      bool matchesCategory = true;
      if (category != 'Semua') {
        matchesCategory = tx.category == category;
      }

      return matchesQuery && matchesDate && matchesCategory;
    }).toList()..sort((a, b) => b.date.compareTo(a.date)); // Tetap urutkan yang terbaru
  }
}