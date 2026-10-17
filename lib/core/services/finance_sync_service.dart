import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/transaction/domain/entities/transaction_entity.dart';
import '../../features/transaction/domain/entities/transaction_type.dart';
import '../../features/transaction/presentation/controllers/transaction_provider.dart';
import '../../features/wallet/presentation/controllers/wallet_provider.dart';
import '../../features/debt/domain/entities/debt_entity.dart';

enum FinanceSyncMode {
  manual,
  automatic,
  disabled;

  static FinanceSyncMode fromString(String? value) {
    switch (value) {
      case 'automatic':
        return FinanceSyncMode.automatic;
      case 'disabled':
        return FinanceSyncMode.disabled;
      case 'manual':
      default:
        return FinanceSyncMode.manual;
    }
  }

  String toValue() {
    switch (this) {
      case FinanceSyncMode.automatic:
        return 'automatic';
      case FinanceSyncMode.disabled:
        return 'disabled';
      case FinanceSyncMode.manual:
        return 'manual';
    }
  }

  String get label {
    switch (this) {
      case FinanceSyncMode.automatic:
        return 'Otomatis';
      case FinanceSyncMode.manual:
        return 'Manual';
      case FinanceSyncMode.disabled:
        return 'Nonaktif';
    }
  }

  String get description {
    switch (this) {
      case FinanceSyncMode.automatic:
        return 'Otomatis kurangi/tambah saldo dompet default';
      case FinanceSyncMode.manual:
        return 'Pilih lokasi saldo/dompet saat transaksi';
      case FinanceSyncMode.disabled:
        return 'Hanya sebagai catatan (tanpa ubah saldo dompet)';
    }
  }
}

class FinanceSyncService {
  static const String _syncModeKey = 'finance_sync_mode';
  static const String _defaultWalletKey = 'finance_sync_default_wallet';

  static final FinanceSyncService instance = FinanceSyncService._internal();
  FinanceSyncService._internal();

  /// Mendapatkan mode sinkronisasi saat ini
  Future<FinanceSyncMode> getSyncMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_syncModeKey);
    return FinanceSyncMode.fromString(modeStr);
  }

  /// Mengubah mode sinkronisasi
  Future<void> setSyncMode(FinanceSyncMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncModeKey, mode.toValue());
  }

  /// Mendapatkan dompet default untuk mode otomatis
  Future<String> getDefaultWallet(BuildContext context) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final savedWallet = prefs.getString(_defaultWalletKey);
    if (savedWallet != null && savedWallet.trim().isNotEmpty) {
      return savedWallet;
    }
    // Fallback dompet pertama
    if (walletProvider.wallets.isNotEmpty) {
      return walletProvider.wallets.first.name;
    }
    return 'Dompet';
  }

  /// Menyimpan dompet default
  Future<void> setDefaultWallet(String walletName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultWalletKey, walletName);
  }

  /// Catat transaksi untuk Nabung atau Tarik Tabungan
  Future<bool> recordWishlistTransaction({
    required BuildContext context,
    required String wishlistTitle,
    required double amount,
    required String walletName,
    required bool isWithdraw,
  }) async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final mode = await getSyncMode();
    if (mode == FinanceSyncMode.disabled) return true;

    try {
      final id = const Uuid().v4();
      final title = isWithdraw ? "Pencairan Tabungan: $wishlistTitle" : "Menabung: $wishlistTitle";
      final type = isWithdraw ? TransactionType.income : TransactionType.expense;

      final tx = TransactionEntity(
        id: id,
        title: title,
        amount: amount,
        date: DateTime.now(),
        type: type,
        category: 'Investasi',
        wallet: walletName,
        source: 'Wishlist',
      );

      return await txProvider.addTransaction(tx);
    } catch (e) {
      debugPrint("Gagal sinkronisasi transaksi tabungan: $e");
      return false;
    }
  }

  /// Catat transaksi untuk Pelunasan Hutang atau Piutang
  Future<bool> recordDebtTransaction({
    required BuildContext context,
    required DebtEntity debt,
    required String walletName,
  }) async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final mode = await getSyncMode();
    if (mode == FinanceSyncMode.disabled) return true;

    try {
      final id = const Uuid().v4();
      final bool isHutang = debt.type == 'Borrowed';
      final type = isHutang ? TransactionType.expense : TransactionType.income;
      final title = isHutang ? "Pelunasan Hutang: ${debt.name}" : "Pelunasan Piutang: ${debt.name}";

      final tx = TransactionEntity(
        id: id,
        title: title,
        amount: debt.amount,
        date: DateTime.now(),
        type: type,
        category: isHutang ? 'Transfer' : 'Hadiah',
        wallet: walletName,
        source: 'Hutang',
      );

      return await txProvider.addTransaction(tx);
    } catch (e) {
      debugPrint("Gagal sinkronisasi transaksi hutang: $e");
      return false;
    }
  }
}
