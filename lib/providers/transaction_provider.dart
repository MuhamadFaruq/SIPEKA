import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  // --- DATABASE SEMENTARA ---
  List<Transaction> _transactions = []; // Menghapus keyword 'final' agar bisa dikosongkan

  List<Transaction> get transactions {
    return [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
  }

  // GETTER SALDO
  double get dompetBalance {
    var filtered = _transactions.where((tx) => tx.wallet == 'Dompet');
    double income = filtered.where((tx) => tx.type == 'Pemasukan').fold(0, (sum, item) => sum + item.amount);
    double expense = filtered.where((tx) => tx.type == 'Pengeluaran').fold(0, (sum, item) => sum + item.amount);
    return income - expense;
  }

  double get ewalletBalance {
    var filtered = _transactions.where((tx) => tx.wallet == 'E-Wallet');
    double income = filtered.where((tx) => tx.type == 'Pemasukan').fold(0, (sum, item) => sum + item.amount);
    double expense = filtered.where((tx) => tx.type == 'Pengeluaran').fold(0, (sum, item) => sum + item.amount);
    return income - expense;
  }

  List<Transaction> getRecentTransactions({int limit = 5}) {
    return transactions.take(limit).toList();
  }

  List<Transaction> getTransactionsByMonth({required int month, required int year}) {
    return _transactions.where((tx) {
      return tx.date.month == month && tx.date.year == year;
    }).toList();
  }

  double getTotalExpense() {
    return _transactions
        .where((tx) => tx.type == 'Pengeluaran')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // --- CRUD (Create, Read, Update, Delete) ---

  Future<void> addTransaction(Transaction tx) async {
    _transactions.add(tx);
    notifyListeners();
  }

  void editTransaction(Transaction editedTx) {
    int index = _transactions.indexWhere((tx) => tx.id == editedTx.id);
    if (index >= 0) {
      _transactions[index] = editedTx;
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  // --- FITUR RESET: UNTUK MENGHAPUS SEMUA DATA KE NOL ---
  void clearAllData() {
    _transactions = []; // Mengosongkan daftar transaksi
    notifyListeners();  // Memperbarui UI agar saldo dan list menjadi kosong
  }
}