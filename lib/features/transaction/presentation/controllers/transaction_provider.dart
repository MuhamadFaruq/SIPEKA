import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sipeka/core/database/database_helper.dart';
import 'package:sipeka/core/services/ocr_helper.dart';
import 'package:sipeka/core/services/sync_service.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/datasources/transaction_remote_datasource.dart';

class TransactionProvider with ChangeNotifier {
  final GetTransactionsUseCase getTransactionsUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  List<TransactionEntity> _transactions = [];
  List<TransactionEntity> _sortedTransactions = []; // Cache sorted list
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Mengembalikan cache yang sudah diurutkan
  List<TransactionEntity> get transactions => _sortedTransactions;

  TransactionProvider({
    GetTransactionsUseCase? getTransactionsUseCase,
    AddTransactionUseCase? addTransactionUseCase,
    DeleteTransactionUseCase? deleteTransactionUseCase,
  })  : getTransactionsUseCase = getTransactionsUseCase ??
            GetTransactionsUseCase(
              TransactionRepositoryImpl(
                localDataSource: TransactionLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: TransactionRemoteDataSourceImpl(SyncService()),
              ),
            ),
        addTransactionUseCase = addTransactionUseCase ??
            AddTransactionUseCase(
              TransactionRepositoryImpl(
                localDataSource: TransactionLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: TransactionRemoteDataSourceImpl(SyncService()),
              ),
            ),
        deleteTransactionUseCase = deleteTransactionUseCase ??
            DeleteTransactionUseCase(
              TransactionRepositoryImpl(
                localDataSource: TransactionLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: TransactionRemoteDataSourceImpl(SyncService()),
              ),
            );

  // Panggil ini setiap kali _transactions berubah
  void _updateSortedCache() {
    _sortedTransactions = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
  }

  // --- FETCH DATA (LOKAL) ---
  Future<void> fetchAndSetTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final dataList = await getTransactionsUseCase();
      _transactions = dataList;
      _updateSortedCache(); // Update cache setelah fetch
    } catch (e) {
      debugPrint("Error Fetching Data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CRUD FUNCTIONS ---
  Future<bool> addTransaction(TransactionEntity tx) async {
    // 1. Update List di Memori (Optimistic Update)
    _transactions.insert(0, tx);
    _updateSortedCache(); // Update cache
    notifyListeners();

    // 2. Simpan ke Database
    try {
      final success = await addTransactionUseCase(tx);
      if (!success) {
        // Rollback jika gagal
        _transactions.remove(tx);
        _updateSortedCache();
        notifyListeners();
        return false;
      }
      debugPrint("Berhasil simpan transaksi: ${tx.title}");
      return true;
    } catch (e) {
      debugPrint("Gagal simpan transaksi: $e");
      // Rollback jika gagal
      _transactions.remove(tx);
      _updateSortedCache();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteTransaction(String id) async {
    // 1. Hapus dari memori & Lokal
    _transactions.removeWhere((tx) => tx.id == id);
    _updateSortedCache(); // Update cache
    notifyListeners();

    try {
      await deleteTransactionUseCase(id);
    } catch (e) {
      debugPrint("Gagal hapus lokal: $e");
    }
  }

  // --- FUNGSI SCAN NOTA (ML KIT) ---
  Future<double?> scanReceipt() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) return null;

      double? detectedTotal = await OCRHelper.extractTotal(pickedFile.path);
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
    double income = filtered.where((tx) => tx.type == TransactionType.income).fold(0, (sum, item) => sum + item.amount);
    double expense = filtered.where((tx) => tx.type == TransactionType.expense).fold(0, (sum, item) => sum + item.amount);
    return income - expense;
  }

  Future<void> clearAllData() async {
    _transactions = [];
    _sortedTransactions = [];
    notifyListeners();
    await DatabaseHelper.instance.clearAllTables();
  }

  Future<void> loadTransactions() async {
    await fetchAndSetTransactions();
  }

  List<TransactionEntity> getFilteredTransactions({
    required String query,
    DateTimeRange? dateRange,
    String category = 'Semua',
    String wallet = 'Semua',
    String type = 'Semua',
  }) {
    return _transactions.where((tx) {
      // 1. Filter Kata Kunci (Judul)
      final matchesQuery = tx.title.toLowerCase().contains(query.toLowerCase());

      // 2. Filter Rentang Tanggal
      bool matchesDate = true;
      if (dateRange != null) {
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

      // 4. Filter Wallet
      bool matchesWallet = true;
      if (wallet != 'Semua') {
        matchesWallet = tx.wallet.toLowerCase() == wallet.toLowerCase();
      }

      // 5. Filter Tipe
      bool matchesType = true;
      if (type != 'Semua') {
        if (type == 'Pemasukan') {
          matchesType = tx.type == TransactionType.income;
        } else if (type == 'Pengeluaran') {
          matchesType = tx.type == TransactionType.expense;
        }
      }

      return matchesQuery && matchesDate && matchesCategory && matchesWallet && matchesType;
    }).toList()..sort((a, b) => b.date.compareTo(a.date)); // Tetap urutkan yang terbaru
  }
}
