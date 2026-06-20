import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/constants/constants.dart';
import 'package:sipeka/core/services/ai_service.dart';

class TransactionHelper {
  // --- FUNGSI FORMAT TEKS SUARA KE RUPIAH (Rp.xxx) ---
  static String formatVoiceTextToRupiah(String text) {
    String formatted = text;

    // 1. Cari angka diikuti "ribu" atau "rb" (cth: "30-ribu", "30rb")
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d+[\d\.,]*)\s*(ribu|rb)\b', caseSensitive: false),
      (match) {
        String numStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
        double? val = double.tryParse(numStr);
        if (val != null) {
          final formattedVal = NumberFormat('#,###', 'id_ID').format(val * 1000);
          return 'Rp.${formattedVal}';
        }
        return match.group(0)!;
      }
    );

    // 2. Cari angka diikuti "juta" (cth: "1.5 juta", "1 juta")
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d+[\d\.,]*)\s*juta\b', caseSensitive: false),
      (match) {
        String numStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
        double? val = double.tryParse(numStr);
        if (val != null) {
          final formattedVal = NumberFormat('#,###', 'id_ID').format(val * 1000000);
          return 'Rp.${formattedVal}';
        }
        return match.group(0)!;
      }
    );

    // 3. Cari angka diikuti "k" (cth: "25k", "25 k")
    formatted = formatted.replaceAllMapped(
      RegExp(r'\b(\d+[\d\.,]*)\s*k\b', caseSensitive: false),
      (match) {
        String numStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
        double? val = double.tryParse(numStr);
        if (val != null) {
          final formattedVal = NumberFormat('#,###', 'id_ID').format(val * 1000);
          return 'Rp.${formattedVal}';
        }
        return match.group(0)!;
      }
    );

    // 4. Cari angka biasa yang diawali "rp" atau "rp." (cth: "rp 30000", "rp.30000")
    formatted = formatted.replaceAllMapped(
      RegExp(r'\brp\.?\s*(\d+[\d\.,]*)\b', caseSensitive: false),
      (match) {
        String numStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
        double? val = double.tryParse(numStr);
        if (val != null) {
          final formattedVal = NumberFormat('#,###', 'id_ID').format(val);
          return 'Rp.${formattedVal}';
        }
        return match.group(0)!;
      }
    );

    // 5. Cari angka biasa yang tidak memiliki prefix "Rp" (cth: "30000")
    // Kita hanya ingin memformat angka yang kemungkinan besar nominal uang (panjangnya >= 4 digit)
    formatted = formatted.replaceAllMapped(
      RegExp(r'\b(\d{4,12})\b'),
      (match) {
        String numStr = match.group(1)!;
        double? val = double.tryParse(numStr);
        if (val != null) {
          final formattedVal = NumberFormat('#,###', 'id_ID').format(val);
          return 'Rp.${formattedVal}';
        }
        return match.group(0)!;
      }
    );

    // 6. Jika ada kata "rupiah" setelah nominal, kita rapikan (cth: "Rp.30.000 rupiah" -> "Rp.30.000")
    formatted = formatted.replaceAllMapped(
      RegExp(r'(Rp\.\d+[\d\.,]*)\s*rupiah', caseSensitive: false),
      (match) => match.group(1)!
    );

    return formatted;
  }

  // --- FUNGSI KAPITALISASI TIAP KATA (Capitalized Case) ---
  static String toCapitalizedCase(String text) {
    if (text.isEmpty) return text;
    return text.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // --- 1. FUNGSI PEMROSES DATA SUARA DENGAN AI ---
  // --- HELPER PARSER LOKAL (INSTAN & OFFLINE) ---
  static Map<String, dynamic>? parseLocally(String text) {
    String cleanText = text.toLowerCase().trim();
    double amount = 0;
    String title = text;

    // 1. Cari pola angka dengan "ribu" atau "rb"
    // Contoh: "20 ribu", "20rb", "20.000 ribu"
    final ribuanReg = RegExp(r'(\d+[\d\.,]*)\s*(ribu|rb)');
    final ribuanMatch = ribuanReg.firstMatch(cleanText);
    if (ribuanMatch != null) {
      String numStr = ribuanMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
      double? val = double.tryParse(numStr);
      if (val != null) {
        amount = val * 1000;
        title = text.replaceRange(ribuanMatch.start, ribuanMatch.end, '').trim();
      }
    } else {
      // 2. Cari pola angka dengan "k"
      // Contoh: "25k", "25 k"
      final kReg = RegExp(r'(\d+[\d\.,]*)\s*k\b');
      final kMatch = kReg.firstMatch(cleanText);
      if (kMatch != null) {
        String numStr = kMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
        double? val = double.tryParse(numStr);
        if (val != null) {
          amount = val * 1000;
          title = text.replaceRange(kMatch.start, kMatch.end, '').trim();
        }
      } else {
        // 3. Cari pola angka biasa dengan prefix "rp" atau "rp."
        // Contoh: "rp30.000", "rp. 30.000", "rp 30000"
        final rpReg = RegExp(r'rp\.?\s*(\d+[\d\.,]*)');
        final rpMatch = rpReg.firstMatch(cleanText);
        if (rpMatch != null) {
          String numStr = rpMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
          double? val = double.tryParse(numStr);
          if (val != null) {
            amount = val;
            title = text.replaceRange(rpMatch.start, rpMatch.end, '').trim();
          }
        } else {
          // 4. Cari angka biasa yang paling besar panjangnya di dalam teks
          // Contoh: "makan mie ayam 30000"
          final genericNumReg = RegExp(r'\b(\d+[\d\.,]*)\b');
          final matches = genericNumReg.allMatches(cleanText);
          double maxVal = 0;
          Match? bestMatch;
          for (var match in matches) {
            String numStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
            double? val = double.tryParse(numStr);
            if (val != null && val > maxVal) {
              maxVal = val;
              bestMatch = match;
            }
          }
          if (bestMatch != null) {
            amount = maxVal;
            title = text.replaceRange(bestMatch.start, bestMatch.end, '').trim();
          }
        }
      }
    }

    // Bersihkan kata residu seperti "rp", "sebesar", "beli" di awal/akhir
    title = title.replaceAll(RegExp(r'\brp\.?\b', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\bsebesar\b', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\buntuk\b', caseSensitive: false), '');
    title = title.trim();

    if (title.isEmpty) {
      title = "Transaksi Suara";
    }

    if (amount > 0) {
      return {
        'title': title,
        'amount': amount,
      };
    }
    return null;
  }

  // --- 1. FUNGSI PEMROSES DATA SUARA DENGAN PARSER LOKAL & FALLBACK AI ---
  static Future<void> processVoiceData({
    required BuildContext context,
    required String rawText,
  }) async {
    // Check budget categories first
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final userCategories = budgetProvider.budgets.map((b) => b.category).toList();
    
    if (userCategories.isEmpty) {
      SipekaNotification.showWarning(
        context,
        "Anggaran kosong! Buat anggaran terlebih dahulu di menu Anggaran sebelum menggunakan input suara.",
      );
      return;
    }

    // Cobalah parse secara lokal terlebih dahulu (instan, offline, & zero-latency)
    final localResult = parseLocally(rawText);
    if (localResult != null) {
      final String title = localResult['title'];
      final double amount = localResult['amount'];
      
      // Deteksi kategori pertama dari kecocokan kata kunci lokal jika memungkinkan
      String detectedCategory = userCategories.first;
      for (var cat in userCategories) {
        if (rawText.toLowerCase().contains(cat.toLowerCase())) {
          detectedCategory = cat;
          break;
        }
      }

      showConfirmationDialog(
        context: context,
        label: toCapitalizedCase(title),
        category: detectedCategory,
        amount: amount,
        icon: Icons.mic,
        source: "Voice Command (Local)",
      );
      return;
    }

    // Jika gagal parse secara lokal, gunakan AI (Gemini) sebagai cadangan
    final aiService = AiService();
    try {
      aiService.validateApiKey();
    } catch (e) {
      SipekaNotification.showWarning(context, AiService.formatError(e));
      return;
    }

    BuildContext? dialogContext;

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final parsedData = await aiService.parseVoiceToTransaction(rawText, userCategories);

      // Tutup loading dialog secara aman menggunakan dialogContext
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (parsedData != null && parsedData.containsKey('amount')) {
        String labelText = parsedData['title']?.toString() ?? 'Transaksi Suara';
        double amount = (parsedData['amount'] is num) 
            ? (parsedData['amount'] as num).toDouble() 
            : double.tryParse(parsedData['amount'].toString()) ?? 0;
            
        String foundCategory = parsedData['category']?.toString() ?? userCategories.first;

        if (amount <= 0) {
          if (!context.mounted) return;
          SipekaNotification.showWarning(context, "Gagal mengekstrak nominal angka. Harap sebutkan nominal transaksi.");
          return;
        }

        if (!context.mounted) return;
        showConfirmationDialog(
          context: context,
          label: toCapitalizedCase(labelText),
          category: foundCategory,
          amount: amount,
          icon: Icons.mic,
          source: "Voice Command (AI)",
        );
      } else {
        if (!context.mounted) return;
        SipekaNotification.showWarning(context, "Gagal memahami nominal. Harap sebutkan angka transaksi.");
      }
    } catch (e) {
      // Tutup loading jika error secara aman menggunakan dialogContext
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        SipekaNotification.showWarning(context, AiService.formatError(e));
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

  // --- 3. FUNGSI DIALOG KONFIRMASI (VERSI FINAL FIX DENGAN PILIHAN KATEGORI) ---
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
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    // Dapatkan kategori aktif dari Anggaran
    List<String> categories = List<String>.from(budgetProvider.activeCategories);
    if (categories.isEmpty) {
      SipekaNotification.showWarning(
        context,
        "Anggaran kosong! Buat anggaran terlebih dahulu di menu Anggaran sebelum menggunakan input suara.",
      );
      return;
    }

    // Pastikan category yang dideteksi oleh AI ada dalam daftar pilihan (case-insensitive check)
    String selectedCategory;
    final existingIndex = categories.indexWhere((c) => c.toLowerCase() == category.toLowerCase());
    if (existingIndex != -1) {
      selectedCategory = categories[existingIndex];
    } else {
      // Jika kategori tidak terdaftar di anggaran, pakai kategori pertama dari anggaran
      selectedCategory = categories.first;
    }

    categories = categories.toSet().toList();

    String currentSelCategory = selectedCategory;

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // Menghindari dialog tertutup tanpa sengaja
      builder: (BuildContext ctx) {

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue), 
              const SizedBox(width: 10), 
              Text(
                "Konfirmasi Transaksi", 
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)
              )
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext stateCtx, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TRANSAKSI", 
                    style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label, 
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    "NOMINAL PENGELUARAN", 
                    style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount), 
                    style: GoogleFonts.nunito(fontSize: 22, color: AppColors.expenseRed, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "KATEGORI", 
                    style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentSelCategory,
                        isExpanded: true,
                        dropdownColor: Theme.of(context).cardColor,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                        style: GoogleFonts.nunito(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 14,
                        ),
                        items: categories.map((String cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(
                                  AppIcons.getIcon(cat),
                                  size: 18,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(cat, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              currentSelCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Sumber: $source", 
                          style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey)
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, {'save': false}), 
              child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey, fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, {'save': true, 'category': currentSelCategory}), 
              child: Text("Simpan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold))
            ),
          ],
        );
      },
    );

    if (result != null && result['save'] == true) {
      final finalCategory = result['category'] ?? category;
      final newTx = Transaction(
        id: const Uuid().v4(),
        title: label,
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: finalCategory,
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
