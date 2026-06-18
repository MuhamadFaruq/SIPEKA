import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/constants/constants.dart';
import 'package:sipeka/core/services/ai_service.dart';

class TransactionHelper {
  // --- 1. FUNGSI PEMROSES DATA SUARA DENGAN AI ---
  static Future<void> processVoiceData({
    required BuildContext context,
    required String rawText,
  }) async {
    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final userCategories = budgetProvider.budgets.map((b) => b.category).toList();

      final aiService = AiService();
      final parsedData = await aiService.parseVoiceToTransaction(rawText, userCategories);

      // Tutup loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (parsedData != null && parsedData.containsKey('amount')) {
        // AI mengembalikan JSON dengan key yang sesuai
        String labelText = parsedData['title']?.toString() ?? 'Transaksi Suara';
        double amount = (parsedData['amount'] is num) 
            ? (parsedData['amount'] as num).toDouble() 
            : double.tryParse(parsedData['amount'].toString()) ?? 0;
            
        String foundCategory = parsedData['category']?.toString() ?? 'Lainnya';

        if (amount <= 0) {
          if (!context.mounted) return;
          SipekaNotification.showWarning(context, "Gagal mengekstrak data nominal dari suara.");
          return;
        }

        if (!context.mounted) return;
        showConfirmationDialog(
          context: context,
          label: labelText.toUpperCase(),
          category: foundCategory,
          amount: amount,
          icon: Icons.mic,
          source: "Voice Command (AI)",
        );
      } else {
        if (!context.mounted) return;
        SipekaNotification.showWarning(context, "Gagal memahami instruksi suara.");
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading jika error
        SipekaNotification.showWarning(context, "Terjadi kesalahan sistem saat memproses suara.");
      }
    }
  }

  // --- 2. FUNGSI POP-UP PEMILIH KATEGORI ---
  static void showCategorySelector({
    required BuildContext context,
    required String rawText,
    required double amount,
    required List<String> categories,
    required String source,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Pilih Kategori", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              if (categories.isEmpty)
                const Center(child: Text("Belum ada kategori anggaran."))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(AppIcons.getIcon(categories[index]), color: const Color(0xFF007AFF)),
                        title: Text(categories[index], style: GoogleFonts.nunito()),
                        onTap: () {
                          Navigator.pop(ctx);
                          showConfirmationDialog(
                            context: context,
                            label: rawText,
                            category: categories[index],
                            amount: amount,
                            icon: source == "Voice Command" ? Icons.mic : Icons.bolt_rounded,
                            source: source,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. FUNGSI DIALOG KONFIRMASI (ASYNC/AWAIT) ---
  // --- 3. FUNGSI DIALOG KONFIRMASI (VERSI FINAL FIX) ---
  static void showConfirmationDialog({
    required BuildContext context,
    required String label,
    required String category,
    required double amount,
    required IconData icon,
    required String source,
  }) async {
    // 1. Ambil Provider di awal agar context tetap aman (Capture)
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Menghindari dialog tertutup tanpa sengaja
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(icon, color: const Color(0xFF007AFF)), 
            const SizedBox(width: 10), 
            const Text("Konfirmasi")
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount), 
                style: GoogleFonts.nunito(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)
              ),
              Text("Sumber: $source", style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Simpan")),
          ],
        );
      },
    );

    if (shouldSave == true) {
      final newTx = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: label,
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: category,
        wallet: 'Dompet',
        source: source,
      );

      // 1. Eksekusi simpan
      bool success = await txProvider.addTransaction(newTx); 
      
      // 2. Cek apakah widget masih nempel di layar
      if (!context.mounted) return;

      if (success) {
        await txProvider.fetchAndSetTransactions();
        if (!context.mounted) return;

        // ✅ Lebih reliable dari Future.delayed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SipekaNotification.showSuccess(context, "Berhasil mencatat $label");
          debugPrint("DEBUG: showSuccess dipanggil");
        });
      } else {
        if (!context.mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SipekaNotification.showWarning(context, "Gagal mencatat transaksi.");
        });
      }
    }
  }
}
