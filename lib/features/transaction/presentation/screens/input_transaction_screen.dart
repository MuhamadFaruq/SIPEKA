import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/features/debt/presentation/screens/debt_screen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:sipeka/core/services/ocr_helper.dart';
import 'package:sipeka/core/services/notifications.dart'; 
import 'package:sipeka/core/theme/theme_provider.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/widgets/custom_numpad.dart';

class InputTransactionScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialAmount;

  const InputTransactionScreen({
    super.key, 
    this.initialCategory, 
    this.initialAmount
  });

  @override
  State<InputTransactionScreen> createState() => _InputTransactionScreenState();
}

class _InputTransactionScreenState extends State<InputTransactionScreen> {
  String _inputAmount = '0';
  String _type = 'Pengeluaran'; 
  String _selectedWallet = 'Dompet'; 
  // --- MODIFIKASI 1: Set default ke null agar user dipaksa memilih ---
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkLostData();
    
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
      _type = 'Pengeluaran'; 
    }
    if (widget.initialAmount != null) {
      _inputAmount = widget.initialAmount!;
    }
  }

  // --- FIX 4: Pastikan fungsi retrieve data dipanggil di initState ---
  Future<void> checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return;
      
      // Jika ada data yang tertinggal akibat app di-kill oleh sistem
      _processImageResult(response.file!);
    } catch (e) {
      debugPrint("Lost Data Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    double dompetBalance = _calculateBalance(provider.transactions, 'Dompet');
    double eWalletBalance = _calculateBalance(provider.transactions, 'E-Wallet');

    return Scaffold(
      // --- FIX: Background dinamis ---
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Tambah Transaksi", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: "Scan Nota",
            onPressed: () => _processScan(),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long), 
            onPressed: () => Navigator.push(context, SmoothPageRoute(child: const DebtScreen())),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 10),
                _buildHeaderNominal(context), 
                const SizedBox(height: 20),
                _buildTypeSelector(context),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildWalletCard(context, "Dompet", dompetBalance, Icons.wallet, _selectedWallet == 'Dompet'),
                    const SizedBox(width: 12),
                    _buildWalletCard(context, "E-Wallet", eWalletBalance, Icons.credit_card, _selectedWallet == 'E-Wallet'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_type == 'Pengeluaran' ? "Kategori Pengeluaran" : "Sumber Pemasukan", 
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                
                if (_type == 'Pengeluaran' && budgetProvider.budgets.isEmpty)
                  _buildEmptyBudgetWarning()
                else
                  _buildDynamicCategories(context),

                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: "Catatan (Opsional)",
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Theme.of(context).cardColor,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDatePicker(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
          CustomNumpad(
            onKeyPressed: (key) {
              setState(() {
                if (_inputAmount == '0') {
                  _inputAmount = key;
                } else {
                  _inputAmount += key;
                }
              });
            },
            onDelete: () {
              setState(() {
                _inputAmount = _inputAmount.length > 1
                    ? _inputAmount.substring(0, _inputAmount.length - 1)
                    : '0';
              });
            },
            onSubmit: _saveTransaction,
          ),
        ],
      ),
    );
  }

  // --- COMPONENT HELPERS ---

  Widget _buildEmptyBudgetWarning() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: InkWell(
        onTap: () => Navigator.pop(context, 2), 
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(height: 8),
              Text(
                "Belum ada anggaran. Klik di sini untuk membuat anggaran terlebih dahulu!",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade300)
        ),
        child: Center(
          child: Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold, 
              fontSize: 15, 
              color: Theme.of(context).textTheme.bodyLarge?.color
            )),
        ),
      ),
    );
  }

  Widget _buildHeaderNominal(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.black.withOpacity(0.05), 
            blurRadius: 10, offset: const Offset(0, 5)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Berapa Nih?", style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),
          Center(
            child: Text(_formatCurrency(_inputAmount),
              style: GoogleFonts.nunito(fontSize: 38, fontWeight: FontWeight.bold, color: _type == 'Pengeluaran' ? AppColors.expenseRed : AppColors.incomeGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicCategories(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    List<Map<String, dynamic>> categoriesToShow = [];

    if (_type == 'Pengeluaran') {
      categoriesToShow = budgetProvider.budgets.map((b) {
        return <String, dynamic>{
          'icon': IconData(b.iconCode, fontFamily: 'MaterialIcons'),
          'label': b.category,
          'val': b.category
        };
      }).toList();
    } else {
      categoriesToShow = [
        <String, dynamic>{'icon': Icons.work, 'label': 'Gaji', 'val': 'Gaji'},
        <String, dynamic>{'icon': Icons.card_giftcard, 'label': 'Hadiah', 'val': 'Hadiah'},
        <String, dynamic>{'icon': Icons.monetization_on, 'label': 'Bonus', 'val': 'Bonus'},
        <String, dynamic>{'icon': Icons.storefront, 'label': 'Jualan', 'val': 'Penjualan'},
        <String, dynamic>{'icon': Icons.add_circle_outline, 'label': 'Lainnya', 'val': 'Lainnya'},
      ];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: categoriesToShow.map((cat) {
          bool isSelected = _selectedCategory == cat['val'];
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['val'] as String),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlue : Theme.of(context).cardColor, 
                      shape: BoxShape.circle,
                      // Tambahkan border merah tipis jika belum pilih agar user ngeh
                      border: Border.all(
                        color: _selectedCategory == null && _type == 'Pengeluaran' 
                          ? Colors.redAccent.withOpacity(0.3) 
                          : Colors.transparent
                      ),
                      boxShadow: isSelected ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                    ),
                    child: Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(cat['label'] as String, style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color
                  ))
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(30)
      ),
      child: Row(
        children: [
          _buildTypeButton("Pengeluaran", AppColors.expenseRed, _type == 'Pengeluaran'),
          _buildTypeButton("Pemasukan", AppColors.incomeGreen, _type == 'Pemasukan'),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, Color color, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { 
          _type = label; 
          _selectedCategory = null; // Reset kategori saat ganti tipe
        }),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? color : Colors.transparent, borderRadius: BorderRadius.circular(30)),
          alignment: Alignment.center,
          child: Text(label, style: GoogleFonts.nunito(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, String name, double balance, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWallet = name),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, 
            borderRadius: BorderRadius.circular(16), 
            border: isSelected ? Border.all(color: AppColors.primaryBlue, width: 2) : Border.all(color: Colors.white10)
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primaryBlue : Colors.orange, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, 
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color
                )),
                Text(NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp').format(balance), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]))
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---

  double _calculateBalance(List<Transaction> transactions, String walletName) {
    double bal = 0;
    for (var tx in transactions) {
      if (tx.wallet == walletName) {
        if (tx.type == TransactionType.income) {
          bal += tx.amount;
        } else {
          bal -= tx.amount;
        }
      }
    }
    return bal;
  }

  String _formatCurrency(String amountStr) {
    double value = double.tryParse(amountStr) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, 
      initialDate: _selectedDate, 
      firstDate: DateTime(2020), 
      lastDate: DateTime(2030), 
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primaryBlue)
        ), 
        child: child!
      )
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveTransaction() {
    double amount = double.tryParse(_inputAmount) ?? 0;

    // --- AMBIL DATA NAMA DARI PROVIDER ---
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    String namaUser = themeProvider.userName;

    if (amount <= 0) {
      SipekaNotification.showWarning(context, "Nominalnya diisi dulu $namaUser!");
      return;
    }

    // VALIDASI WAJIB PILIH KATEGORI
    if (_selectedCategory == null) {
      HapticFeedback.vibrate(); 
      // --- SEKARANG PESANNYA DINAMIS ---
      SipekaNotification.showWarning(
        context, 
        "Pilih kategori Pengeluaran dulu, $namaUser!"
      );
      return;
    }

    final newTx = Transaction(
      id: const Uuid().v4(),
      // Gunakan null check operator ! karena sudah divalidasi di atas
      title: _noteController.text.isEmpty ? _selectedCategory! : _noteController.text,
      amount: amount,
      date: _selectedDate,
      type: _type == 'Pengeluaran' ? TransactionType.expense : TransactionType.income,
      category: _selectedCategory!, 
      wallet: _selectedWallet,
    );

    // BUDGET OVERSPENDING CHECK
    if (_type == 'Pengeluaran') {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final budgetIndex = budgetProvider.budgets.indexWhere((b) => b.category == _selectedCategory);
      
      if (budgetIndex != -1) {
        final budget = budgetProvider.budgets[budgetIndex];
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        
        // Calculate total expenses for this category in the current month
        final now = DateTime.now();
        double currentSpent = transactionProvider.transactions
            .where((tx) => tx.category == _selectedCategory && 
                           tx.type == TransactionType.expense && 
                           tx.date.month == now.month && 
                           tx.date.year == now.year)
            .fold(0.0, (sum, tx) => sum + tx.amount);

        if (currentSpent + amount > budget.limit) {
          _showOverspendingWarningDialog(budget.limit, currentSpent + amount, () {
            _executeSave(newTx);
          });
          return;
        }
      }
    }

    _executeSave(newTx);
  }

  // --- FIX 1: Gunakan variabel picker global untuk konsistensi ---
  final ImagePicker _picker = ImagePicker();

  void _processScan() async {
    try {
      // FIX 2: Tambahkan feedback getar agar user tahu proses dimulai
      HapticFeedback.mediumImpact();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        // FIX 3: Resolusi 1080p dengan kualitas 50% adalah "Sweet Spot"
        // agar OCR tetap tajam tapi RAM tidak meledak
        imageQuality: 50, 
        maxWidth: 1080, 
        maxHeight: 1920,
      );

      if (image != null) {
        _processImageResult(image);
      }
    } catch (e) {
      debugPrint("Error Camera: $e");
      SipekaNotification.showWarning(context, "Kamera tidak bisa dibuka. Cek izin aplikasi.");
    }
  }

  void _processImageResult(XFile image) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [ 
        AndroidUiSettings(
          toolbarTitle: 'Fokuskan pada Total Belanja',
          toolbarColor: AppColors.primaryBlue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings( 
          title: 'Fokuskan pada Total Belanja',
          doneButtonTitle: 'Selesai',
          cancelButtonTitle: 'Batal',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return;

    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      },
    );

    try {
      double? result = await OCRHelper.extractTotal(croppedFile.path);
      
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (result != null && result > 0) {
        HapticFeedback.lightImpact();
        setState(() {
          _inputAmount = result.toInt().toString();
          _type = 'Pengeluaran'; 
          _selectedCategory = null;
        });
        if (mounted) {
          SipekaNotification.showSuccess(context, "Berhasil mendeteksi: ${_formatCurrency(_inputAmount)}");
        }
      } else {
        if (mounted) {
          SipekaNotification.showWarning(context, "Gagal mendeteksi angka. Coba foto ulang.");
        }
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        SipekaNotification.showWarning(context, "Gagal memproses gambar: $e");
      }
    }
  }



  void _executeSave(Transaction newTx) async {
    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await Provider.of<TransactionProvider>(context, listen: false).addTransaction(newTx);
      
      // Tutup loading dialog secara aman
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      
      if (success) {
        if (mounted) {
          Navigator.pop(context); // Kembali ke screen sebelumnya menggunakan screen's navigator
          SipekaNotification.showSuccess(context, "Mantap! Transaksimu berhasil disimpan.");
        }
      } else {
        if (mounted) {
          SipekaNotification.showWarning(context, "Gagal menyimpan transaksi ke database.");
        }
      }
    } catch (e) {
      // Tutup loading jika error secara aman
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        SipekaNotification.showWarning(context, "Terjadi kesalahan: $e");
      }
    }
  }

  void _showOverspendingWarningDialog(double limit, double totalProjected, VoidCallback onConfirm) {
    final diff = totalProjected - limit;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              Text("Anggaran Terlampaui!", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pengeluaran ini akan melebihi batas anggaran kategori '$_selectedCategory'.",
                style: GoogleFonts.nunito(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Batas Anggaran:", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13)),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(limit),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Pengeluaran:", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13)),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalProjected),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppColors.expenseRed, fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text(
                "Lebih sebesar Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(diff)} dari batas anggaran bulanan.",
                style: GoogleFonts.nunito(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: Text("TETAP SIMPAN", style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}