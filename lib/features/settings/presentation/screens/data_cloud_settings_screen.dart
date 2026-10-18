import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipeka/core/constants/constants.dart';
import 'package:sipeka/core/services/auth_service.dart';
import 'package:sipeka/core/services/firestore_service.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/debt/presentation/controllers/debt_provider.dart';
import 'package:sipeka/features/wishlist/presentation/controllers/wishlist_provider.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/bill/presentation/controllers/bill_provider.dart';
import 'package:sipeka/features/quick_action/presentation/controllers/quick_action_provider.dart';

class DataCloudSettingsScreen extends StatelessWidget {
  const DataCloudSettingsScreen({super.key});

  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  Widget _buildCard({required BuildContext context, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 10),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildCloudAccountTile(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return _buildListTile(
            context: context,
            icon: Icons.cloud_off,
            title: "Belum Terhubung",
            subtitle: "Klik untuk login Google & cadangkan data",
            color: Colors.orange,
            onTap: () async {
              final auth = AuthService();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
              try {
                final prevUid = FirestoreService.instance.userId;
                final user = await auth.signInWithGoogle();
                if (!context.mounted) return;
                Navigator.pop(context); // Tutup loading dialog
                if (user != null) {
                  await FirestoreService.instance.migrateDataBetweenUsers(prevUid, user.uid);
                  if (context.mounted) {
                    Provider.of<TransactionProvider>(context, listen: false).fetchAndSetTransactions();
                    Provider.of<BudgetProvider>(context, listen: false).fetchAndSetBudgets();
                    Provider.of<DebtProvider>(context, listen: false).fetchAndSetDebts();
                    Provider.of<WishlistProvider>(context, listen: false).fetchAndSetWishlist();
                    Provider.of<WalletProvider>(context, listen: false).fetchAndSetWallets();
                    Provider.of<BillProvider>(context, listen: false).fetchBills();
                  }
                  SipekaNotification.showSuccess(context, "Selamat datang, ${user.displayName}!");
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Tutup loading dialog
                _showSignInErrorDiagnostics(context, e);
              }
            },
          );
        }

        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null ? const Icon(Icons.person) : null,
          ),
          title: Text(
            user.displayName ?? "Pengguna Google",
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            user.email ?? "",
            style: GoogleFonts.nunito(fontSize: 11),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                SipekaNotification.showWarning(context, "Berhasil logout");
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text(
          "Data & Cadangan Cloud",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startBlue, endBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(context, "Akun Cloud SIPEKA"),
          _buildCard(
            context: context,
            child: _buildCloudAccountTile(context),
          ),
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Sinkronisasi & Cadangan"),
          _buildCard(
            context: context,
            child: Column(
              children: [
                _buildListTile(
                  context: context,
                  icon: Icons.cloud_sync,
                  title: "Sinkronisasi Cloud",
                  subtitle: "Cadangkan & pulihkan data ke Google Cloud/Firestore",
                  color: Colors.blueAccent,
                  onTap: () async {
                    final authService = AuthService();
                    final currentUser = await authService.user.first;

                    if (currentUser == null) {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_sync, color: Colors.blueAccent, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Text("Login Diperlukan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Untuk menyimpan atau memulihkan data ke Cloud, Anda perlu login dengan akun Google terlebih dahulu.",
                                style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  icon: Image.asset('assets/images/google_logo.png', height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 20)),
                                  label: Text("Lanjutkan dengan Google", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (c) => const Center(child: CircularProgressIndicator()),
                                    );
                                    try {
                                      final prevUid = FirestoreService.instance.userId;
                                      final user = await authService.signInWithGoogle();
                                      if (!context.mounted) return;
                                      Navigator.pop(context); // Tutup loading dialog
                                      if (user != null) {
                                        await FirestoreService.instance.migrateDataBetweenUsers(prevUid, user.uid);
                                        if (context.mounted) {
                                          Provider.of<TransactionProvider>(context, listen: false).fetchAndSetTransactions();
                                          Provider.of<BudgetProvider>(context, listen: false).fetchAndSetBudgets();
                                          Provider.of<DebtProvider>(context, listen: false).fetchAndSetDebts();
                                          Provider.of<WishlistProvider>(context, listen: false).fetchAndSetWishlist();
                                          Provider.of<WalletProvider>(context, listen: false).fetchAndSetWallets();
                                          Provider.of<BillProvider>(context, listen: false).fetchBills();
                                        }
                                        SipekaNotification.showSuccess(context, "Login berhasil!");
                                        Future.delayed(const Duration(milliseconds: 300), () {
                                          if (!context.mounted) return;
                                          _showSyncOptionsDialog(context, user);
                                        });
                                      } else {
                                        SipekaNotification.showWarning(context, "Login dibatalkan.");
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      Navigator.pop(context); // Tutup loading dialog
                                      _showSignInErrorDiagnostics(context, e);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      if (context.mounted) {
                        _showSyncOptionsDialog(context, currentUser);
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  context: context,
                  icon: Icons.cloud_upload_outlined,
                  title: "Ekspor Data (CSV)",
                  subtitle: "Unduh dan bagikan data ke file Spreadsheet CSV",
                  color: Colors.blue,
                  onTap: () => _showExportOptions(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Zona Bahaya"),
          _buildCard(
            context: context,
            child: _buildListTile(
              context: context,
              icon: Icons.restore_from_trash_rounded,
              title: "Reset Semua Data",
              subtitle: "Hapus seluruh catatan lokal & mulai dari nol",
              color: Colors.red,
              onTap: () => _confirmResetDataSafe(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetDataSafe(BuildContext context) {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Konfirmasi Hapus Data", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Tindakan ini permanen. Ketik 'HAPUS' di bawah untuk melanjutkan:", style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyMedium?.color)),
            const SizedBox(height: 15),
            TextField(
              controller: confirmController,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: "Ketik HAPUS",
                hintStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (confirmController.text == "HAPUS") {
                Navigator.pop(ctx);

                final txProvider = Provider.of<TransactionProvider>(context, listen: false);
                final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
                final debtProvider = Provider.of<DebtProvider>(context, listen: false);
                final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
                final quickActionProvider = Provider.of<QuickActionProvider>(context, listen: false);
                final walletProvider = Provider.of<WalletProvider>(context, listen: false);
                final billProvider = Provider.of<BillProvider>(context, listen: false);

                await FirestoreService.instance.clearAllUserData();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await quickActionProvider.clearAll();

                if (context.mounted) {
                  txProvider.clearAllData();
                  budgetProvider.clearAllData();
                  debtProvider.clearAllData();
                  wishlistProvider.clearAllData();
                  await walletProvider.clearAllData();
                  await billProvider.clearAllData();
                  await walletProvider.fetchAndSetWallets();

                  SipekaNotification.showSuccess(context, "Semua data telah dihapus!");
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } else {
                SipekaNotification.showWarning(context, "Kata konfirmasi salah.");
              }
            },
            child: Text("HAPUS SEKARANG", style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSyncOptionsDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_sync, color: Colors.blueAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Sinkronisasi Cloud",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Akun terhubung: ${user.email}",
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Pilih tindakan sinkronisasi:",
              style: GoogleFonts.nunito(fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text("Cadangkan ke Cloud (Backup)", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                _confirmBackupDialog(context);
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text("Pulihkan dari Cloud (Restore)", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                _confirmRestoreDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _confirmBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Konfirmasi Cadangkan Data", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          "Peringatan: Tindakan ini akan mengunggah data lokal saat ini dari handphone Anda ke server cloud SIPEKA dan menimpa cadangan lama jika ada.\n\nApakah Anda yakin ingin mencadangkan data sekarang?",
          style: GoogleFonts.nunito(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _runSyncProcess(context, isBackup: true);
            },
            child: Text("Cadangkan Sekarang", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Konfirmasi Pemulihan Data", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          "Peringatan: Seluruh data transaksi lokal saat ini di handphone ini akan dihapus dan digantikan dengan data cadangan dari server cloud SIPEKA. Tindakan ini tidak dapat dibatalkan.\n\nApakah Anda yakin ingin melanjutkan?",
          style: GoogleFonts.nunito(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _runSyncProcess(context, isBackup: false);
            },
            child: Text("Pulihkan Sekarang", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _runSyncProcess(BuildContext context, {required bool isBackup}) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              isBackup ? "Mengunggah data ke Cloud..." : "Mengunduh data dari Cloud...",
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 14, decoration: TextDecoration.none),
            ),
          ],
        ),
      ),
    );

    try {
      if (isBackup) {
        if (!context.mounted) return;
        Navigator.pop(context); // Tutup loading dialog
        SipekaNotification.showSuccess(context, "Data Anda tersinkronisasi otomatis dengan Firestore secara real-time!");
      } else {
        await transactionProvider.fetchAndSetTransactions();
        await budgetProvider.fetchAndSetBudgets();
        await debtProvider.fetchAndSetDebts();
        await wishlistProvider.fetchAndSetWishlist();
        await walletProvider.fetchAndSetWallets();
        await billProvider.fetchBills();

        if (!context.mounted) return;
        Navigator.pop(context); // Tutup loading dialog
        SipekaNotification.showSuccess(context, "Data berhasil dimuat ulang dari Firestore!");
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      SipekaNotification.showWarning(context, "Gagal sinkronisasi: ${e.toString()}");
    }
  }

  void _showSignInErrorDiagnostics(BuildContext context, Object error) {
    String message = error.toString();
    String solution = "Terjadi kesalahan yang tidak dikenal saat menghubungkan ke Google.";

    if (message.contains("10") || message.toLowerCase().contains("developer_error")) {
      solution = "Penyebab Umum: SHA-1 fingerprint dari keystore aplikasi Anda belum didaftarkan di Firebase Console untuk aplikasi Android com.example.sipeka.\n\n"
          "Cara Memperbaiki:\n"
          "1. Generate SHA-1 debug keystore Anda.\n"
          "2. Masuk ke Firebase Console -> Project Settings -> SDK Setup -> Tambahkan fingerprint SHA-1.\n"
          "3. Unduh google-services.json yang baru dan gantikan yang lama di android/app/google-services.json.";
    } else if (message.contains("12500") || message.toLowerCase().contains("sign_in_failed")) {
      solution = "Penyebab Umum: Metode login Google belum diaktifkan di Firebase Console.\n\n"
          "Cara Memperbaiki:\n"
          "1. Masuk ke Firebase Console -> Authentication -> Sign-in method.\n"
          "2. Klik 'Add new provider' -> pilih 'Google'.\n"
          "3. Aktifkan (Enable) dan pilih email dukungan project (Project support email), lalu klik Simpan.";
    } else if (message.contains("7") || message.toLowerCase().contains("network_error")) {
      solution = "Penyebab: Koneksi internet terputus atau tidak stabil. Pastikan perangkat Anda terhubung ke internet dengan baik.";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Google Link Gagal", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Detail Error:",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: GoogleFonts.nunito(fontSize: 12, color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Text(
                "Solusi / Panduan:",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                solution,
                style: GoogleFonts.nunito(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _exportToCSV(BuildContext context, {String type = "ALL"}) async {
    List<List<dynamic>> rows = [];
    String fileName = "laporan_sipeka";
    if (type == "ALL" || type == "TRANSAKSI") {
      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      if (txProvider.transactions.isNotEmpty) {
        rows.add(["DATA TRANSAKSI"]);
        rows.add(["Tanggal", "Judul", "Nominal", "Kategori", "Dompet", "Tipe"]);
        for (var tx in txProvider.transactions) {
          rows.add([tx.date.toString(), tx.title, tx.amount, tx.category, tx.wallet, tx.type.toString()]);
        }
        rows.add([]);
      }
    }
    if (type == "ALL" || type == "HUTANG") {
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      if (debtProvider.debts.isNotEmpty) {
        rows.add(["DATA HUTANG PIUTANG"]);
        rows.add(["Nama", "Nominal", "Tipe", "Status", "Tgl Pinjam", "Tgl Lunas", "Catatan"]);
        for (var d in debtProvider.debts) {
          rows.add([
            d.name,
            d.amount,
            d.type == 'Borrowed' ? 'Hutang' : 'Piutang',
            d.isPaid ? "Lunas" : "Belum Lunas",
            d.date.toString(),
            d.paidDate?.toString() ?? "-",
            d.notes ?? "-"
          ]);
        }
        rows.add([]);
      }
    }
    if (type == "ALL" || type == "ANGGARAN") {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      if (budgetProvider.budgets.isNotEmpty) {
        rows.add(["DATA ANGGARAN"]);
        rows.add(["Kategori", "Batas Limit (Rp)"]);
        for (var b in budgetProvider.budgets) {
          rows.add([b.category, b.limit]);
        }
      }
    }
    if (rows.isEmpty) {
      SipekaNotification.showWarning(context, "Tidak ada data untuk diekspor");
      return;
    }
    try {
      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/${fileName}_${type.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Laporan Keuangan SIPEKA ($type)',
        ),
      );
      if (context.mounted) {
        SipekaNotification.showSuccess(context, "Berhasil mengekspor data $type!");
      }
    } catch (e) {
      if (context.mounted) {
        SipekaNotification.showWarning(context, "Gagal ekspor: $e");
      }
    }
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text("Pilih Data yang Diekspor", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.all_inclusive, color: Colors.blue),
            title: const Text("Semua Data (Gabungan)"),
            onTap: () {
              Navigator.pop(ctx);
              _exportToCSV(context, type: "ALL");
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.green),
            title: const Text("Hanya Transaksi"),
            onTap: () {
              Navigator.pop(ctx);
              _exportToCSV(context, type: "TRANSAKSI");
            },
          ),
          ListTile(
            leading: const Icon(Icons.handshake_outlined, color: Colors.orange),
            title: const Text("Hanya Hutang Piutang"),
            onTap: () {
              Navigator.pop(ctx);
              _exportToCSV(context, type: "HUTANG");
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline, color: Colors.purple),
            title: const Text("Hanya Daftar Anggaran"),
            onTap: () {
              Navigator.pop(ctx);
              _exportToCSV(context, type: "ANGGARAN");
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
