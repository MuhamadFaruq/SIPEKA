import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transaction_model.dart';
import '../utils/ocr_helper.dart';
import '../utils/database_helper.dart'; // Import Helper Database

class TransactionProvider with ChangeNotifier {
  // --- STATE MEMORY ---
  List<Transaction> _transactions = [];

  // Getter yang otomatis mengurutkan berdasarkan tanggal terbaru
  List<Transaction> get transactions {
    return [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
  }

  final TextEditingController nominalController = TextEditingController();

  // --- FUNGSI DATABASE (FETCH DATA) ---
  // Panggil fungsi ini di initState HomeScreen atau MainNavigation
  Future<void> fetchAndSetTransactions() async {
    final dataList = await DatabaseHelper.instance.getAllTransactions();
    _transactions = dataList.map((item) => Transaction(
      id: item['id'],
      title: item['title'],
      amount: item['amount'],
      date: DateTime.parse(item['date']),
      type: item['type'],
      category: item['category'],
      wallet: item['wallet'],
    )).toList();
    notifyListeners();
  }

  // --- FUNGSI SCAN NOTA ---
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
      print("Error scanning: $e");
      return null;
    }
  }

  // --- GETTER SALDO (REAL-TIME DARI MEMORI) ---
  double get dompetBalance {
    var filtered = _transactions.where((tx) => tx.wallet == 'Dompet');
    double income = filtered.where((tx) => tx.type == 'Pemasukan' || tx.type == 'Income').fold(0, (sum, item) => sum + item.amount);
    double expense = filtered.where((tx) => tx.type == 'Pengeluaran' || tx.type == 'Expense').fold(0, (sum, item) => sum + item.amount);
    return income - expense;
  }

  double get ewalletBalance {
    var filtered = _transactions.where((tx) => tx.wallet == 'E-Wallet');
    double income = filtered.where((tx) => tx.type == 'Pemasukan' || tx.type == 'Income').fold(0, (sum, item) => sum + item.amount);
    double expense = filtered.where((tx) => tx.type == 'Pengeluaran' || tx.type == 'Expense').fold(0, (sum, item) => sum + item.amount);
    return income - expense;
  }

  // --- CRUD FUNCTIONS (SINKRON DENGAN SQLITE) ---

  Future<void> addTransaction(Transaction tx) async {
    // 1. Tambah ke memori (UI langsung update)
    _transactions.add(tx);
    notifyListeners();

    // 2. Simpan permanen ke SQLite
    await DatabaseHelper.instance.insertTransaction({
      'id': tx.id,
      'title': tx.title,
      'amount': tx.amount,
      'date': tx.date.toIso8601String(),
      'type': tx.type,
      'category': tx.category,
      'wallet': tx.wallet,
    });
  }

  Future<void> deleteTransaction(String id) async {
    // 1. Hapus dari memori
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();

    // 2. Hapus dari database
    await DatabaseHelper.instance.deleteTransaction(id);
  }

  // Digunakan untuk reset data jika diperlukan di Settings
  Future<void> clearAllData() async {
    _transactions = [];
    notifyListeners();
    // Tambahkan fungsi truncate di DatabaseHelper jika ingin hapus semua di DB
  }

  @override
  void dispose() {
    nominalController.dispose();
    super.dispose();
  }
}