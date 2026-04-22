import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/notifications.dart';
import '../utils/constants.dart';

class TransactionHelper {
  // --- 1. FUNGSI PEMROSES DATA SUARA ---
  static void processVoiceData({
    required BuildContext context,
    required String rawText,
  }) {
    String text = rawText.toLowerCase();
    String cleanText = text.replaceAll('.', '').replaceAll(',', '');

    double amount = 0;
    List<String> words = cleanText.split(' ');
    String labelText = "";

    // Logika Multiplier
    double currentMultiplier = 1;
    if (cleanText.contains("juta")) currentMultiplier = 1000000;
    else if (cleanText.contains("ribu") || cleanText.contains("rb")) currentMultiplier = 1000;

    // Ambil angka
    List<String> foundNumbers = [];
    for (var word in words) {
      final match = RegExp(r'(\d+)').firstMatch(word);
      if (match != null) {
        foundNumbers.add(match.group(0)!);
      } else if (word != "juta" && word != "ribu" && word != "jt" && word != "rb") {
        labelText += "$word ";
      }
    }

    if (foundNumbers.isNotEmpty) {
      String fullNumberStr = foundNumbers.join('');
      amount = (double.tryParse(fullNumberStr) ?? 0) * currentMultiplier;
    }

    if (amount == 0) {
      SipekaNotification.showWarning(context, "Nominal tidak terdeteksi.");
      return;
    }

    // Ambil Kategori dari BudgetProvider
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final userCategories = budgetProvider.budgets.map((b) => b.category).toList();

    String? foundCategory;
    for (String cat in userCategories) {
      if (text.contains(cat.toLowerCase())) {
        foundCategory = cat;
        break;
      }
    }

    if (foundCategory != null) {
      showConfirmationDialog(
        context: context,
        label: labelText.trim().toUpperCase(),
        category: foundCategory,
        amount: amount,
        icon: Icons.mic,
        source: "Voice Command",
      );
    } else {
      showCategorySelector(
        context: context,
        rawText: labelText.trim().toUpperCase(),
        amount: amount,
        categories: userCategories,
        source: "Voice Command",
      );
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
        type: 'Expense',
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