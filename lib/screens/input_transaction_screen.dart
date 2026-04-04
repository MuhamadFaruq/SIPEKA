import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart'; 
import '../models/transaction_model.dart';
import 'debt_screen.dart'; 
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../utils/ocr_helper.dart';

class MyTransactionPage extends StatefulWidget {
  const MyTransactionPage({super.key});

  @override
  _MyTransactionPageState createState() => _MyTransactionPageState();
}

class _MyTransactionPageState extends State<MyTransactionPage> {
  final ImagePicker picker = ImagePicker(); // Inisialisasi picker

  // 2. Taruh kodenya di dalam fungsi asinkron seperti ini
  Future<void> _getImageFromCamera() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1080, // Resolusi aman untuk Samsung S21 FE
      );

      if (image != null) {
        // Panggil fungsi OCR kamu di sini
        _processOCR(image); 
      }
    } catch (e) {
      print("Error saat mengambil gambar: $e");
      // Opsional: Berikan feedback ke user lewat SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil gambar: $e")),
      );
    }
  }

  // Fungsi OCR kamu
  Future<void> _processOCR(XFile image) async {
    // Logika pemrosesan teks ML Kit kamu di sini...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... UI SIPEKA ...
      floatingActionButton: FloatingActionButton(
        onPressed: _getImageFromCamera, // 3. Panggil fungsinya di sini
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

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
  String _selectedCategory = 'Lainnya'; 
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);
  final Color colorExpense = const Color(0xFFFF5252);
  final Color colorIncome = const Color(0xFF00C853);

  // 1. Tambahkan ini di dalam class State
  @override
  void initState() {
    super.initState();
    // Cek apakah ada data yang tertinggal setelah crash kamera
    checkLostData();
    
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
      _type = 'Pengeluaran'; 
    }
    if (widget.initialAmount != null) {
      _inputAmount = widget.initialAmount!;
    }
  }

  // 2. Fungsi untuk mengambil data yang "hilang" tadi
  Future<void> checkLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) return;
    
    if (response.file != null) {
      // Jika ada file yang terselamatkan, langsung proses scan
      _processImageResult(response.file!);
    } else {
      print("Error Lost Data: ${response.exception?.code}");
    }
  }

  // 3. Pisahkan logika pemrosesan agar bisa dipanggil dari mana saja
  void _processImageResult(XFile image) async {
    // Pindahkan seluruh logika ImageCropper dan OCRHelper ke sini
    // (Logika yang sebelumnya ada di dalam _processScan setelah "if (image != null)")
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    
    double dompetBalance = _calculateBalance(provider.transactions, 'Dompet');
    double eWalletBalance = _calculateBalance(provider.transactions, 'E-Wallet');

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text("Tambah Transaksi", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startBlue, endBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol Scan Nota Baru
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined), // Ikon scan
            tooltip: "Scan Nota",
            onPressed: () => _processScan(),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtScreen())),
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
                _buildHeaderNominal(), 
                const SizedBox(height: 20),
                _buildTypeSelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildWalletCard("Dompet", dompetBalance, Icons.wallet, _selectedWallet == 'Dompet'),
                    const SizedBox(width: 12),
                    _buildWalletCard("E-Wallet", eWalletBalance, Icons.credit_card, _selectedWallet == 'E-Wallet'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_type == 'Pengeluaran' ? "Kategori Pengeluaran" : "Sumber Pemasukan", 
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                
                // VALIDASI: Tampilkan pesan jika pengeluaran tapi belum ada anggaran
                // Cari bagian ini di dalam ListView:
                if (_type == 'Pengeluaran' && budgetProvider.budgets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: InkWell( // Bungkus dengan InkWell agar bisa diklik
                      onTap: () {
                        // TUTUP layar input dan KIRIM data index ke-2 (Anggaran)
                        Navigator.pop(context, 2); 
                      },
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
                              style: GoogleFonts.nunito(
                                color: Colors.redAccent, 
                                fontSize: 13, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _buildDynamicCategories(),

                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: "Catatan (Opsional)",
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), 
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: Center(
                      child: Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                        style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildSimpleNumpad(),
        ],
      ),
    );
  }

  Widget _buildHeaderNominal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Berapa Nih?", style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 5),
          Center(
            child: Text(_formatCurrency(_inputAmount),
              style: GoogleFonts.nunito(fontSize: 38, fontWeight: FontWeight.bold, color: _type == 'Pengeluaran' ? colorExpense : colorIncome)),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleNumpad() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNumRow(['1', '2', '3']),
          const SizedBox(height: 10),
          _buildNumRow(['4', '5', '6']),
          const SizedBox(height: 10),
          _buildNumRow(['7', '8', '9']),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildNumKey('000'), const SizedBox(width: 10),
              _buildNumKey('0'), const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _inputAmount = _inputAmount.length > 1 ? _inputAmount.substring(0, _inputAmount.length - 1) : '0';
                    }),
                    child: const SizedBox(height: 48, child: Icon(Icons.backspace_outlined, color: Colors.red, size: 20)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity, height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [startBlue, endBlue]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveTransaction,
                child: Text("SIMPAN TRANSAKSI", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(children: [
      _buildNumKey(keys[0]), const SizedBox(width: 10),
      _buildNumKey(keys[1]), const SizedBox(width: 10),
      _buildNumKey(keys[2])
    ]);
  }

  Widget _buildNumKey(String key) {
    return Expanded(
      child: Material(
        color: Colors.grey[50], borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            if (_inputAmount == '0') {
              _inputAmount = key;
            } else {
              _inputAmount += key;
            }
          }),
          child: Container(
            height: 48, alignment: Alignment.center,
            child: Text(key, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // --- FUNGSI KATEGORI DINAMIS (FIX ERROR & IKON MANUAL) ---
  Widget _buildDynamicCategories() {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    List<Map<String, dynamic>> categoriesToShow = [];

    if (_type == 'Pengeluaran') {
      if (budgetProvider.budgets.isNotEmpty) {
        // Konversi anggaran menjadi list kategori dengan ikon manual
        categoriesToShow = budgetProvider.budgets.map((b) {
          return <String, dynamic>{
            'icon': IconData(b.iconCode, fontFamily: 'MaterialIcons'),
            'label': b.category,
            'val': b.category
          };
        }).toList();

      } else {
        categoriesToShow = []; 
      }
    } else {
      // Kategori Pemasukan Statis
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
                      color: isSelected ? startBlue : Colors.white, 
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                    ),
                    child: Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(cat['label'] as String, style: GoogleFonts.nunito(fontSize: 10))
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          _buildTypeButton("Pengeluaran", colorExpense, _type == 'Pengeluaran'),
          _buildTypeButton("Pemasukan", colorIncome, _type == 'Pemasukan'),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, Color color, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { 
          _type = label; 
          _selectedCategory = label == 'Pengeluaran' ? 'Lainnya' : 'Gaji'; 
        }),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? color : Colors.transparent, borderRadius: BorderRadius.circular(30)),
          alignment: Alignment.center,
          child: Text(label, style: GoogleFonts.nunito(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildWalletCard(String name, double balance, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWallet = name),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16), 
            border: isSelected ? Border.all(color: startBlue, width: 2) : null
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? startBlue : Colors.orange, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp').format(balance), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]))
            ],
          ),
        ),
      ),
    );
  }

  double _calculateBalance(List<Transaction> transactions, String walletName) {
    double bal = 0;
    for (var tx in transactions) {
      if (tx.wallet == walletName) {
        if (tx.type == 'Income' || tx.type == 'Pemasukan') {
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
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: startBlue)), 
        child: child!
      )
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveTransaction() {
    double amount = double.tryParse(_inputAmount) ?? 0;

    // VALIDASI 1: Nominal masih nol
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nominalnya diisi dulu ya!"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // VALIDASI 2: Catatan/Title kosong (Opsional, tergantung keinginanmu)
    if (_noteController.text.isEmpty && _selectedCategory == 'Lainnya') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kasih keterangan dikit dong biar nggak bingung."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Jika lolos validasi, baru simpan
    final newTx = Transaction(
      id: DateTime.now().toString(),
      title: _noteController.text.isEmpty ? _selectedCategory : _noteController.text,
      amount: amount,
      date: _selectedDate,
      type: _type == 'Pengeluaran' ? 'Expense' : 'Income',
      category: _selectedCategory,
      wallet: _selectedWallet,
    );

    Provider.of<TransactionProvider>(context, listen: false).addTransaction(newTx);
    
    // FEEDBACK: Berhasil Simpan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Mantap! Transaksi berhasil disimpan."),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  void _processScan() async {
    final picker = ImagePicker();
    
    try {
      // 1. Ambil Gambar dengan Proteksi Memori (maxWidth & imageQuality)
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, 
        maxWidth: 1080,  
        maxHeight: 1920, 
      );

      if (image != null) {
        // 2. Cropping (Bisa juga dibungkus try-catch jika ingin lebih aman)
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Fokuskan pada Total Belanja',
              toolbarColor: startBlue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Fokuskan pada Total Belanja',
            ),
          ],
        );

        if (croppedFile != null) {
          _showLoadingDialog();

          // 3. Jalankan OCR
          double? result = await OCRHelper.extractTotal(croppedFile.path);
          
          if (mounted) Navigator.pop(context); // Tutup loading

          if (result != null && result > 0) {
            HapticFeedback.lightImpact();
            setState(() {
              _inputAmount = result.toInt().toString();
              _type = 'Pengeluaran'; 
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Berhasil mendeteksi: ${_formatCurrency(_inputAmount)}"),
                backgroundColor: startBlue,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Gagal mendeteksi angka. Coba foto lebih tegak dan terang."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      // MENANGKAP ERROR JIKA KAMERA CRASH
      print("Error Kamera/OCR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ups! Kamera bermasalah: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tambahkan helper dialog sederhana
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}