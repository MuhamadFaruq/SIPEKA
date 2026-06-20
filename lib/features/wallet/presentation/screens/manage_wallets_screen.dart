import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/wallet_entity.dart';
import '../controllers/wallet_provider.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipeka/core/services/shared_wallet_sync_service.dart';
import 'package:sipeka/core/utils/formatters.dart';

class ManageWalletsScreen extends StatefulWidget {
  const ManageWalletsScreen({super.key});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  final List<Color> _colorPalette = [
    const Color(0xFF2972FF), // Blue
    const Color(0xFF2ECC71), // Green
    const Color(0xFFE74C3C), // Red
    const Color(0xFFF1C40F), // Yellow
    const Color(0xFFE67E22), // Orange
    const Color(0xFF9B59B6), // Purple
    const Color(0xFF1ABC9C), // Teal
    const Color(0xFFE91E63), // Pink
  ];

  final List<IconData> _iconSelection = [
    Icons.wallet_rounded,
    Icons.account_balance_rounded,
    Icons.credit_card_rounded,
    Icons.savings_rounded,
    Icons.money_rounded,
    Icons.payments_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kelola Dompet & Rekening",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.group_add_rounded, size: 18, color: AppColors.primaryBlue),
            label: Text(
              "Gabung",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
                fontSize: 14,
              ),
            ),
            onPressed: () => _showJoinWalletDialog(walletProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: walletProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : walletProvider.wallets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: walletProvider.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = walletProvider.wallets[index];
                    final dynamicBalance = wallet.initialBalance +
                        txProvider.getWalletBalance(wallet.name);

                    return _buildWalletItem(wallet, dynamicBalance, walletProvider);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditWalletDialog(null),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "TAMBAH DOMPET",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Belum ada dompet",
            style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem(WalletEntity wallet, double balance, WalletProvider walletProvider) {
    final walletColor = Color(int.parse(wallet.colorHex.replaceFirst('#', '0xFF')));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: walletColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            IconData(wallet.iconCode, fontFamily: 'MaterialIcons'),
            color: walletColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              wallet.name,
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (wallet.isShared) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 10, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      "Bersama",
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Saldo Awal: Rp ${NumberFormat.decimalPattern('id').format(wallet.initialBalance)}",
              style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey),
            ),
            Text(
              "Saldo Saat Ini: Rp ${NumberFormat.decimalPattern('id').format(balance)}",
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: balance < 0 ? AppColors.expenseRed : AppColors.incomeGreen,
              ),
            ),
            if (wallet.isShared && wallet.inviteCode != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: wallet.inviteCode ?? ''));
                  SipekaNotification.showSuccess(context, "Kode undangan berhasil disalin!");
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Kode: ${wallet.inviteCode}",
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy, size: 12, color: AppColors.primaryBlue),
                  ],
                ),
              ),
            ] else if (!wallet.isShared) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _shareWallet(wallet, walletProvider),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.share, size: 12, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      "Aktifkan Berbagi",
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
              onPressed: () => _showAddEditWalletDialog(wallet),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
              onPressed: () => _confirmDeleteWallet(wallet, walletProvider),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteWallet(WalletEntity wallet, WalletProvider walletProvider) {
    if (walletProvider.wallets.length <= 1) {
      SipekaNotification.showWarning(context, "Anda harus memiliki minimal 1 dompet!");
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Hapus ${wallet.name}?",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Tindakan ini tidak bisa dibatalkan. Semua transaksi di dompet ini akan ikut terhapus dari riwayat keuangan Anda.",
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final txProvider = Provider.of<TransactionProvider>(context, listen: false);
              Navigator.pop(ctx);
              final success = await walletProvider.deleteWallet(wallet.id);
              if (success) {
                // Delete associated transactions
                final toDelete = txProvider.transactions.where((tx) => tx.wallet.toLowerCase() == wallet.name.toLowerCase()).toList();
                for (var tx in toDelete) {
                  await txProvider.deleteTransaction(tx.id);
                }
                if (mounted) {
                  SipekaNotification.showSuccess(context, "Dompet ${wallet.name} berhasil dihapus!");
                }
              } else {
                if (mounted) {
                  SipekaNotification.showWarning(context, "Gagal menghapus dompet.");
                }
              }
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditWalletDialog(WalletEntity? existingWallet) {
    final nameController = TextEditingController(text: existingWallet?.name ?? "");
    final balanceController = TextEditingController(
      text: existingWallet != null
          ? NumberFormat.decimalPattern('id').format(existingWallet.initialBalance.toInt())
          : "",
    );

    Color selectedColor = existingWallet != null
        ? Color(int.parse(existingWallet.colorHex.replaceFirst('#', '0xFF')))
        : _colorPalette[0];

    IconData selectedIcon = existingWallet != null
        ? IconData(existingWallet.iconCode, fontFamily: 'MaterialIcons')
        : _iconSelection[0];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              existingWallet == null ? "Tambah Dompet Baru" : "Edit Dompet",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: "Nama Dompet",
                      labelStyle: GoogleFonts.nunito(color: Colors.grey),
                      hintText: "Contoh: Bank BCA, Cash Tunai",
                      hintStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: balanceController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: "Saldo Awal",
                      labelStyle: GoogleFonts.nunito(color: Colors.grey),
                      hintText: "0",
                      hintStyle: GoogleFonts.nunito(color: Colors.grey),
                      prefixText: "Rp ",
                      prefixStyle: GoogleFonts.nunito(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Pilih Warna Visual",
                      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorPalette.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final color = _colorPalette[idx];
                        final isSelected = selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = color),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Pilih Ikon Representatif",
                      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _iconSelection.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final icon = _iconSelection[idx];
                        final isSelected = selectedIcon.codePoint == icon.codePoint;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedIcon = icon),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? selectedColor : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? selectedColor : Colors.grey,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    SipekaNotification.showWarning(context, "Nama dompet tidak boleh kosong!");
                    return;
                  }

                  final name = nameController.text.trim();
                  final cleanBalance = balanceController.text.replaceAll('.', '');
                  final initialBalance = double.tryParse(cleanBalance) ?? 0.0;
                  final colorHex = '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
                  final iconCode = selectedIcon.codePoint;

                  final walletProvider = Provider.of<WalletProvider>(context, listen: false);

                  // Prevent editing wallet to a name that clashes with another
                  final nameExists = walletProvider.wallets.any((w) =>
                      w.name.toLowerCase() == name.toLowerCase() &&
                      w.id != (existingWallet?.id ?? ""));

                  if (nameExists) {
                    SipekaNotification.showWarning(context, "Nama dompet sudah digunakan!");
                    return;
                  }

                  Navigator.pop(ctx);

                  bool success;
                  if (existingWallet == null) {
                    final newId = const Uuid().v4();
                    final newWallet = WalletEntity(
                      id: newId,
                      name: name,
                      initialBalance: initialBalance,
                      iconCode: iconCode,
                      colorHex: colorHex,
                    );
                    success = await walletProvider.addWallet(newWallet);
                  } else {
                    final updatedWallet = WalletEntity(
                      id: existingWallet.id,
                      name: name,
                      initialBalance: initialBalance,
                      iconCode: iconCode,
                      colorHex: colorHex,
                    );
                    success = await walletProvider.updateWallet(updatedWallet);
                  }

                  if (success) {
                    if (mounted) {
                      SipekaNotification.showSuccess(
                        context,
                        existingWallet == null ? "Dompet berhasil dibuat!" : "Dompet berhasil diperbarui!",
                      );
                    }
                  } else {
                    if (mounted) {
                      SipekaNotification.showWarning(context, "Terjadi kesalahan saat menyimpan dompet.");
                    }
                  }
                },
                child: const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _shareWallet(WalletEntity wallet, WalletProvider walletProvider) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SipekaNotification.showWarning(context, "Harap login ke Akun Google Anda terlebih dahulu untuk menggunakan Dompet Bersama.");
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Jadikan Dompet Bersama?", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text(
          "Anda akan membagikan dompet '${wallet.name}' agar bisa digunakan bersama pasangan/keluarga. Kode undangan unik akan dibuat untuk Anda bagikan ke mereka.",
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () async {
              Navigator.pop(ctx);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              final navigator = Navigator.of(context);
              final txProvider = Provider.of<TransactionProvider>(context, listen: false);

              try {
                final code = await SharedWalletSyncService.instance.shareWallet(wallet);
                navigator.pop(); // Close loading dialog

                if (code != null) {
                  await walletProvider.fetchAndSetWallets();
                  
                  SharedWalletSyncService.instance.startListeningToSharedWallets(
                    onTransactionUpdated: () => txProvider.fetchAndSetTransactions(),
                    onWalletUpdated: () => walletProvider.fetchAndSetWallets(),
                  );

                  if (mounted) {
                    final themeCardColor = Theme.of(context).cardColor;
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: themeCardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text("Berhasil Dibagikan!", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Bagikan kode undangan di bawah ke pasangan atau keluarga Anda:", style: GoogleFonts.nunito(fontSize: 14)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    code,
                                    style: GoogleFonts.nunito(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: AppColors.primaryBlue),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: code));
                                      SipekaNotification.showSuccess(context, "Kode berhasil disalin!");
                                    },
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: Text("OK", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  navigator.pop(); // Close loading dialog
                  SipekaNotification.showWarning(context, "Gagal membagikan dompet: ${e.toString()}");
                }
              }
            },
            child: const Text("YA, BAGIKAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showJoinWalletDialog(WalletProvider walletProvider) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SipekaNotification.showWarning(context, "Harap login ke Akun Google Anda terlebih dahulu untuk bergabung ke Dompet Bersama.");
      return;
    }

    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Gabung Dompet Bersama", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masukkan 6 digit kode undangan untuk menyinkronkan data dompet bersama pasangan atau keluarga Anda.",
              style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              autofocus: true,
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: "CONTOH: X7Y2B9",
                hintStyle: GoogleFonts.nunito(fontSize: 14, letterSpacing: 0, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) {
                SipekaNotification.showWarning(context, "Kode undangan harus 6 karakter!");
                return;
              }

              Navigator.pop(ctx);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              final navigator = Navigator.of(context);
              final txProvider = Provider.of<TransactionProvider>(context, listen: false);

              try {
                final success = await SharedWalletSyncService.instance.joinSharedWallet(code);
                navigator.pop(); // Close loading dialog

                if (success) {
                  await walletProvider.fetchAndSetWallets();
                  await txProvider.fetchAndSetTransactions();

                  SharedWalletSyncService.instance.startListeningToSharedWallets(
                    onTransactionUpdated: () => txProvider.fetchAndSetTransactions(),
                    onWalletUpdated: () => walletProvider.fetchAndSetWallets(),
                  );

                  if (mounted) {
                    SipekaNotification.showSuccess(context, "Berhasil bergabung ke Dompet Bersama!");
                  }
                }
              } catch (e) {
                if (mounted) {
                  navigator.pop(); // Close loading dialog
                  SipekaNotification.showWarning(context, "Gagal bergabung: ${e.toString()}");
                }
              }
            },
            child: const Text("GABUNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
