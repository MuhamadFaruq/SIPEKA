import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:sipeka/core/services/ai_service.dart';
import 'package:sipeka/core/services/notification_service.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/category/presentation/controllers/category_provider.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/wallet/domain/entities/wallet_entity.dart';

class NotificationTrackerScreen extends StatefulWidget {
  final String? initialPayload;

  const NotificationTrackerScreen({super.key, this.initialPayload});

  @override
  State<NotificationTrackerScreen> createState() => _NotificationTrackerScreenState();
}

class _NotificationTrackerScreenState extends State<NotificationTrackerScreen> {
  final TextEditingController _notificationInputController = TextEditingController();
  
  bool _isTrackingEnabled = true;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _notificationHistory = [];
  
  // Template Notifikasi Indonesia
  final List<Map<String, String>> _templates = [
    {
      'title': 'GoPay: Belanja Makanan',
      'text': 'Pembayaran sukses! Anda telah membayar Rp 45.000 ke Solaria Kelapa Gading via GoPay.'
    },
    {
      'title': 'OVO: Transfer Keluar',
      'text': 'Transfer keluar berhasil! Rp 120.000 berhasil dikirim ke Budi Setiawan. Ref: 893201.'
    },
    {
      'title': 'ShopeePay: Belanja Minimarket',
      'text': 'Pembayaran berhasil! Rp 32.500 telah didebit dari ShopeePay Anda untuk merchant Alfamart Merdeka.'
    },
    {
      'title': 'DANA: Kirim Uang',
      'text': 'Kirim uang sukses! Rp 75.000 terkirim ke 081234567890 (Dana Dompet) pada 24/06/2026.'
    },
    {
      'title': 'SMS BCA: Tarik Debit',
      'text': 'SMS BANKING BCA: TRANSAKSI DEBIT RP 250.000 DI TOKOPEDIA VIA KARTU 1234 PADA 24/06 18:20.'
    },
    {
      'title': 'Mandiri: Transfer Masuk',
      'text': 'Livin\' by Mandiri: Dana sebesar Rp 1.500.000 telah masuk ke rekening Anda *1234 dari Budi Setiawan.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndHistory();
    
    // Jika layar dibuka melalui tap notifikasi (membawa payload)
    if (widget.initialPayload != null && widget.initialPayload!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processNotificationText(widget.initialPayload!);
      });
    }
  }

  Future<void> _loadSettingsAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTrackingEnabled = prefs.getBool('ai_notification_tracking_enabled') ?? true;
      
      final historyJson = prefs.getString('ai_notification_history');
      if (historyJson != null) {
        try {
          _notificationHistory = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
        } catch (e) {
          debugPrint("Error decoding history: $e");
        }
      }
    });
  }

  Future<void> _toggleTracking(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTrackingEnabled = value;
    });
    await prefs.setBool('ai_notification_tracking_enabled', value);
    HapticFeedback.mediumImpact();
    
    if (mounted) {
      SipekaNotification.showSuccess(
        context, 
        value ? "Pemantauan Notifikasi AI diaktifkan!" : "Pemantauan Notifikasi AI dinonaktifkan."
      );
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_notification_history', jsonEncode(_notificationHistory));
  }

  void _addNotificationToHistory(String rawText, String title, double amount, String status) {
    setState(() {
      _notificationHistory.insert(0, {
        'id': const Uuid().v4(),
        'rawText': rawText,
        'title': title,
        'amount': amount,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _saveHistory();
  }

  void _updateNotificationStatus(String rawText, String newStatus) {
    final index = _notificationHistory.indexWhere((item) => item['rawText'] == rawText);
    if (index != -1) {
      setState(() {
        _notificationHistory[index]['status'] = newStatus;
      });
      _saveHistory();
    }
  }

  // Memicu notifikasi sistem push nyata
  Future<void> _triggerSystemNotification(String text) async {
    if (!_isTrackingEnabled) {
      SipekaNotification.showWarning(context, "Aktifkan pemantauan notifikasi terlebih dahulu!");
      return;
    }
    
    HapticFeedback.lightImpact();
    // Tampilkan notifikasi push riil menggunakan NotificationService
    await NotificationService.showImmediateNotification(
      id: DateTime.now().millisecond,
      title: "SIPEKA AI: Transaksi Terdeteksi! 🤖",
      body: text.length > 60 ? "${text.substring(0, 57)}..." : text,
      payload: text,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Push notification berhasil dikirim! Silakan geser bilah status HP Anda atau ketuk banner yang muncul.",
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF007AFF),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Memproses teks notifikasi via AI Gemini
  Future<void> _processNotificationText(String text) async {
    if (text.trim().isEmpty) {
      SipekaNotification.showWarning(context, "Masukkan teks notifikasi terlebih dahulu!");
      return;
    }

    setState(() {
      _isLoading = true;
    });
    HapticFeedback.mediumImpact();

    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);

      final availableCategories = categoryProvider.categories.map((c) => c.name).toList();
      final availableWallets = walletProvider.wallets.map((w) => w.name).toList();

      final result = await AiService().parseTransactionNotification(
        notificationText: text,
        availableCategories: availableCategories,
        availableWallets: availableWallets,
      );

      setState(() {
        _isLoading = false;
      });

      if (result == null || result['isValid'] == false) {
        if (mounted) {
          _addNotificationToHistory(text, "Bukan Transaksi Keuangan", 0.0, "ignored");
          _showIgnoredDialog(text);
        }
        return;
      }

      // Berhasil diparsing! Tampilkan Bottom Sheet Konfirmasi AI
      if (mounted) {
        _showConfirmationBottomSheet(text, result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SipekaNotification.showWarning(context, "AI gagal menganalisis teks. Periksa koneksi internet Anda.");
      }
    }
  }

  void _showIgnoredDialog(String rawText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              "Bukan Transaksi",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "AI SIPEKA membaca teks ini bukan sebagai notifikasi transaksi keuangan yang valid (pengeluaran/pemasukan):\n\n\"$rawText\"",
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Tutup",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: const Color(0xFF007AFF)),
            ),
          )
        ],
      ),
    );
  }

  void _showConfirmationBottomSheet(String rawText, Map<String, dynamic> parsed) {
    final double amount = (parsed['amount'] as num?)?.toDouble() ?? 0.0;
    final String merchant = parsed['merchant'] as String? ?? "Merchant";
    final String parsedCategory = parsed['category'] as String? ?? "Belanja";
    final String parsedWallet = parsed['wallet'] as String? ?? "Tunai";
    final String description = parsed['description'] as String? ?? "Pencatatan Otomatis AI";
    final String typeStr = parsed['type'] as String? ?? "EXPENSE";

    TransactionType selectedType = typeStr == "INCOME" ? TransactionType.income : TransactionType.expense;

    final titleController = TextEditingController(text: merchant);
    final amountController = TextEditingController(text: NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(amount).trim());
    final descController = TextEditingController(text: description);

    // Ambil data dari provider
    final categories = Provider.of<CategoryProvider>(context, listen: false).categories;
    final wallets = Provider.of<WalletProvider>(context, listen: false).wallets;

    // Cari entitas terdekat
    String? selectedCategoryId;
    try {
      selectedCategoryId = categories.firstWhere((c) => c.name.toLowerCase() == parsedCategory.toLowerCase()).id;
    } catch (_) {
      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first.id;
      }
    }

    String? selectedWalletName;
    try {
      selectedWalletName = wallets.firstWhere((w) => w.name.toLowerCase() == parsedWallet.toLowerCase()).name;
    } catch (_) {
      if (wallets.isNotEmpty) {
        selectedWalletName = wallets.first.name;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E2E), // Premium Dark
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology_rounded, color: Color(0xFF007AFF), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Konfirmasi Transaksi AI",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Berhasil dideteksi via notifikasi",
                              style: GoogleFonts.nunito(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tipe Transaksi Tab
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = TransactionType.expense),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == TransactionType.expense
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: selectedType == TransactionType.expense ? Colors.red : Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  "Pengeluaran",
                                  style: GoogleFonts.nunito(
                                    color: selectedType == TransactionType.expense ? Colors.redAccent : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = TransactionType.income),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == TransactionType.income
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: selectedType == TransactionType.income ? Colors.green : Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  "Pemasukan",
                                  style: GoogleFonts.nunito(
                                    color: selectedType == TransactionType.income ? Colors.greenAccent : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nominal Field
                    Text(
                      "Nominal (Rp)",
                      style: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.nunito(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        prefixText: "Rp ",
                        prefixStyle: GoogleFonts.nunito(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Merchant/Title Field
                    Text(
                      "Judul Transaksi / Merchant",
                      style: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.nunito(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row Dropdowns (Kategori & Dompet)
                    Row(
                      children: [
                        // Dropdown Kategori
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kategori",
                                style: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCategoryId,
                                    dropdownColor: const Color(0xFF1E1E2E),
                                    isExpanded: true,
                                    style: GoogleFonts.nunito(color: Colors.white),
                                    items: categories.map((c) {
                                      return DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setModalState(() {
                                        selectedCategoryId = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dropdown Dompet
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Dompet",
                                style: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedWalletName,
                                    dropdownColor: const Color(0xFF1E1E2E),
                                    isExpanded: true,
                                    style: GoogleFonts.nunito(color: Colors.white),
                                    items: wallets.map((w) {
                                      return DropdownMenuItem(
                                        value: w.name,
                                        child: Text(w.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setModalState(() {
                                        selectedWalletName = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi Field
                    Text(
                      "Keterangan / Catatan",
                      style: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      style: GoogleFonts.nunito(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Button Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final finalTitle = titleController.text.trim();
                          final cleanVal = amountController.text.replaceAll('.', '').replaceAll(',', '');
                          final finalAmount = double.tryParse(cleanVal) ?? 0.0;

                          if (finalTitle.isEmpty) {
                            SipekaNotification.showWarning(context, "Judul transaksi wajib diisi!");
                            return;
                          }
                          if (finalAmount <= 0) {
                            SipekaNotification.showWarning(context, "Nominal transaksi tidak valid!");
                            return;
                          }

                          Navigator.pop(ctx); // Tutup bottom sheet
                          
                          setModalState(() {
                            _isLoading = true;
                          });

                          // Simpan transaksi
                          final selectedCategory = categories.firstWhere((c) => c.id == selectedCategoryId).name;

                          final tx = TransactionEntity(
                            id: const Uuid().v4(),
                            title: finalTitle,
                            amount: finalAmount,
                            date: DateTime.now(),
                            type: selectedType,
                            category: selectedCategory,
                            wallet: selectedWalletName ?? "Tunai",
                            source: "AI Notification Tracker",
                          );

                          final txProvider = Provider.of<TransactionProvider>(context, listen: false);
                          final wProvider = Provider.of<WalletProvider>(context, listen: false);

                          final success = await txProvider.addTransaction(tx);
                          
                          // Cari dompet dan sesuaikan saldonya di DB
                          if (success) {
                            final targetWallet = wProvider.wallets.firstWhere((w) => w.name == tx.wallet, orElse: () => wallets.first);
                            
                            double newBalance = targetWallet.initialBalance;
                            if (tx.type == TransactionType.expense) {
                              newBalance -= tx.amount;
                            } else {
                              newBalance += tx.amount;
                            }
                            
                            // Update dompet di DB & State
                            final updatedWallet = WalletEntity(
                              id: targetWallet.id,
                              name: targetWallet.name,
                              initialBalance: newBalance,
                              iconCode: targetWallet.iconCode,
                              colorHex: targetWallet.colorHex,
                              inviteCode: targetWallet.inviteCode,
                              ownerId: targetWallet.ownerId,
                              isShared: targetWallet.isShared,
                            );
                            await wProvider.updateWallet(updatedWallet);
                            await wProvider.fetchAndSetWallets();
                            
                            // Simpan atau update log sejarah tracker
                            final exists = _notificationHistory.any((item) => item['rawText'] == rawText);
                            if (exists) {
                              _updateNotificationStatus(rawText, "recorded");
                            } else {
                              _addNotificationToHistory(rawText, finalTitle, finalAmount, "recorded");
                            }
                            HapticFeedback.mediumImpact();
                            
                            if (context.mounted) {
                              SipekaNotification.showSuccess(context, "Transaksi \"$finalTitle\" otomatis disimpan!");
                            }
                          } else {
                            if (context.mounted) {
                              SipekaNotification.showWarning(context, "Gagal menyimpan transaksi ke database.");
                            }
                          }

                          setModalState(() {
                            _isLoading = false;
                          });
                        },
                        child: Text(
                          "SIMPAN TRANSAKSI",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0F0F1A), // Sleek Dark Accent
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0F1A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "AI Notification Sync",
              style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Panel Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E38), Color(0xFF131326)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GlowPulse(isActive: _isTrackingEnabled),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isTrackingEnabled ? "Layanan Pemantauan Aktif" : "Layanan Nonaktif",
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _isTrackingEnabled ? "Mendeteksi SMS & Notifikasi HP" : "Ketuk saklar untuk mengaktifkan",
                                    style: GoogleFonts.nunito(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _isTrackingEnabled,
                            activeThumbColor: const Color(0xFF007AFF),
                            activeTrackColor: const Color(0xFF007AFF).withValues(alpha: 0.3),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.white12,
                            onChanged: _toggleTracking,
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 32),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Colors.white54, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "SIPEKA memproses teks notifikasi secara lokal dengan enkripsi aman sebelum dianalisis oleh AI.",
                              style: GoogleFonts.nunito(color: Colors.white54, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Simulator Playground Section
                Text(
                  "Interactive Simulator Playground",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131326),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pilih Template Notifikasi Keuangan:",
                        style: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      
                      // Horizontal Template Chips
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _templates.length,
                          itemBuilder: (ctx, idx) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(_templates[idx]['title']!),
                                labelStyle: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                backgroundColor: const Color(0xFF1E1E38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onPressed: () {
                                  setState(() {
                                    _notificationInputController.text = _templates[idx]['text']!;
                                  });
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Box
                      TextField(
                        controller: _notificationInputController,
                        maxLines: 3,
                        style: GoogleFonts.nunito(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Tulis atau tempel teks notifikasi bank / SMS di sini...",
                          hintStyle: GoogleFonts.nunito(color: Colors.white30, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0F0F1A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF007AFF)),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.notifications_active_rounded, size: 16),
                                label: Text(
                                  "KIRIM NOTIFIKASI",
                                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF007AFF),
                                  side: const BorderSide(color: Color(0xFF007AFF)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  _triggerSystemNotification(_notificationInputController.text);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.psychology_rounded, size: 18),
                                label: Text(
                                  "PROSES DENGAN AI",
                                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007AFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  _processNotificationText(_notificationInputController.text);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Inbox History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Kotak Masuk Notifikasi Terdeteksi",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_notificationHistory.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _notificationHistory.clear();
                          });
                          _saveHistory();
                          SipekaNotification.showSuccess(context, "Riwayat notifikasi dikosongkan.");
                        },
                        child: Text(
                          "Hapus Semua",
                          style: GoogleFonts.nunito(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // History List
                _notificationHistory.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131326),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.mark_email_read_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 12),
                            Text(
                              "Belum ada notifikasi terdeteksi",
                              style: GoogleFonts.nunito(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _notificationHistory.length,
                        itemBuilder: (ctx, idx) {
                          final item = _notificationHistory[idx];
                          final rawText = item['rawText'] as String? ?? "";
                          final title = item['title'] as String? ?? "Transaksi";
                          final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                          final status = item['status'] as String? ?? "pending";
                          final String timeStr = DateFormat('dd MMM, HH:mm').format(DateTime.parse(item['timestamp']));

                          Color statusColor = Colors.orange;
                          String statusText = "Perlu Tinjauan";
                          IconData statusIcon = Icons.pending_rounded;

                          if (status == "recorded") {
                            statusColor = Colors.green;
                            statusText = "Berhasil Dicatat";
                            statusIcon = Icons.check_circle_rounded;
                          } else if (status == "ignored") {
                            statusColor = Colors.grey;
                            statusText = "Bukan Transaksi";
                            statusIcon = Icons.cancel_outlined;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131326),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(statusIcon, size: 12, color: statusColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusText,
                                            style: GoogleFonts.nunito(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.nunito(color: Colors.white30, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  rawText,
                                  style: GoogleFonts.nunito(color: Colors.white70, fontSize: 12, height: 1.4),
                                ),
                                if (status == "pending") ...[
                                  const Divider(color: Colors.white12, height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Ingin memproses dengan AI?",
                                        style: GoogleFonts.nunito(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(
                                        height: 28,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.15),
                                            foregroundColor: const Color(0xFF007AFF),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          onPressed: () => _processNotificationText(rawText),
                                          child: Text(
                                            "Tinjau & Catat",
                                            style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (status == "recorded") ...[
                                  const Divider(color: Colors.white12, height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.insights_rounded, size: 14, color: Colors.greenAccent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Tercatat: $title sebesar Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(amount).trim()}",
                                          style: GoogleFonts.nunito(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
        
        // 4. Loading Overlay
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Card(
                color: const Color(0xFF131326),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF007AFF)),
                      const SizedBox(height: 20),
                      Text(
                        "AI Menganalisis Notifikasi...",
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mengekstrak nominal & kategori",
                        style: GoogleFonts.nunito(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Glowing Breath Pulse Animation Widget
class GlowPulse extends StatefulWidget {
  final bool isActive;

  const GlowPulse({super.key, required this.isActive});

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12 + (16 * _controller.value),
              height: 12 + (16 * _controller.value),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 1.0 - _controller.value),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF007AFF),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}
