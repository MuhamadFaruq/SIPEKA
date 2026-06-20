import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/bill/presentation/controllers/bill_provider.dart';
import 'package:sipeka/features/bill/domain/entities/bill_entity.dart';
import 'package:sipeka/core/utils/formatters.dart';

class ManageBillsScreen extends StatefulWidget {
  const ManageBillsScreen({super.key});

  @override
  State<ManageBillsScreen> createState() => _ManageBillsScreenState();
}

class _ManageBillsScreenState extends State<ManageBillsScreen> {
  final List<String> _frequencies = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];
  final List<String> _frequenciesDb = ['daily', 'weekly', 'monthly', 'yearly'];

  final List<String> _billCategories = [
    'Tagihan & Utilitas',
    'Hiburan (Netflix/Spotify)',
    'Cicilan & Kredit',
    'Kontrakan & Kost',
    'Pendidikan',
    'Lainnya'
  ];

  IconData _getIconForCategory(String category) {
    if (category.contains('Utilitas') || category.contains('Wifi')) {
      return Icons.wifi_rounded;
    } else if (category.contains('Hiburan') || category.contains('Netflix')) {
      return Icons.tv_rounded;
    } else if (category.contains('Cicilan') || category.contains('Kredit')) {
      return Icons.credit_card_rounded;
    } else if (category.contains('Kontrakan') || category.contains('Kost')) {
      return Icons.home_work_rounded;
    } else if (category.contains('Pendidikan')) {
      return Icons.school_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tagihan & Transaksi Berulang",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: billProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : billProvider.bills.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: billProvider.bills.length,
                  itemBuilder: (context, index) {
                    final bill = billProvider.bills[index];
                    return _buildBillItem(bill, billProvider);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBillDialog(null),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: Text(
          "TAMBAH TAGIHAN",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.repeat_on_rounded, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "Belum Ada Tagihan Rutin",
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Catat biaya langganan bulanan atau cicilan rutin kamu agar otomatis dicatat oleh aplikasi.",
              style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillItem(BillEntity bill, BillProvider billProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryIcon = _getIconForCategory(bill.category);
    final accentColor = bill.type.toLowerCase() == 'income' ? AppColors.incomeGreen : AppColors.expenseRed;

    String freqLabel = 'Bulanan';
    final idx = _frequenciesDb.indexOf(bill.frequency.toLowerCase());
    if (idx != -1) {
      freqLabel = _frequencies[idx];
    }

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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 4),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon,
                color: accentColor,
                size: 24,
              ),
            ),
            title: Text(
              bill.title,
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Rp ${NumberFormat.decimalPattern('id').format(bill.amount)} ($freqLabel)",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Jatuh Tempo: ${DateFormat('d MMMM yyyy', 'id_ID').format(bill.nextExecutionDate)}",
                  style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  "Dompet: ${bill.wallet}",
                  style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                  onPressed: () => _showAddEditBillDialog(bill),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteBill(bill, billProvider),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.power_settings_new_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text("Aktifkan Tagihan", style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: bill.isActive,
                        activeThumbColor: AppColors.primaryBlue,
                        onChanged: (val) async {
                          final updated = BillEntity(
                            id: bill.id,
                            title: bill.title,
                            amount: bill.amount,
                            type: bill.type,
                            category: bill.category,
                            wallet: bill.wallet,
                            frequency: bill.frequency,
                            startDate: bill.startDate,
                            lastExecutedDate: bill.lastExecutedDate,
                            nextExecutionDate: bill.nextExecutionDate,
                            isActive: val,
                            remindMe: bill.remindMe,
                          );
                          await billProvider.updateBill(updated);
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text("Pengingat H-1", style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: bill.remindMe,
                        activeThumbColor: AppColors.primaryBlue,
                        onChanged: bill.isActive ? (val) async {
                          final updated = BillEntity(
                            id: bill.id,
                            title: bill.title,
                            amount: bill.amount,
                            type: bill.type,
                            category: bill.category,
                            wallet: bill.wallet,
                            frequency: bill.frequency,
                            startDate: bill.startDate,
                            lastExecutedDate: bill.lastExecutedDate,
                            nextExecutionDate: bill.nextExecutionDate,
                            isActive: bill.isActive,
                            remindMe: val,
                          );
                          await billProvider.updateBill(updated);
                        } : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBill(BillEntity bill, BillProvider billProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Hapus Tagihan?",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus tagihan rutin '${bill.title}'? Pencatatan otomatis dan pengingat tagihan ini akan dinonaktifkan.",
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
              Navigator.pop(ctx);
              final success = await billProvider.deleteBill(bill.id);
              if (success && mounted) {
                SipekaNotification.showSuccess(context, "Tagihan berhasil dihapus!");
              } else {
                if (mounted) SipekaNotification.showWarning(context, "Gagal menghapus tagihan.");
              }
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditBillDialog(BillEntity? existingBill) {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final wallets = walletProvider.wallets;

    if (wallets.isEmpty) {
      SipekaNotification.showWarning(context, "Buat dompet terlebih dahulu sebelum menjadwalkan tagihan!");
      return;
    }

    final titleController = TextEditingController(text: existingBill?.title ?? "");
    final amountController = TextEditingController(
      text: existingBill != null
          ? NumberFormat.decimalPattern('id').format(existingBill.amount.toInt())
          : "",
    );

    String selectedType = existingBill?.type ?? 'Expense';
    String selectedCategory = existingBill?.category ?? _billCategories[0];
    String selectedWallet = existingBill?.wallet ?? wallets.first.name;
    String selectedFreq = existingBill != null 
        ? _frequencies[_frequenciesDb.indexOf(existingBill.frequency.toLowerCase())]
        : _frequencies[2]; // Monthly default
    DateTime selectedDate = existingBill?.nextExecutionDate ?? DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              existingBill == null ? "Tambah Transaksi Rutin" : "Edit Transaksi Rutin",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Tipe selector (Expense / Income)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Center(child: Text("Pengeluaran", style: GoogleFonts.nunito(fontWeight: FontWeight.bold))),
                          selected: selectedType == 'Expense',
                          selectedColor: AppColors.expenseRed,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(color: selectedType == 'Expense' ? Colors.white : Colors.grey),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = 'Expense');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Center(child: Text("Pemasukan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold))),
                          selected: selectedType == 'Income',
                          selectedColor: AppColors.incomeGreen,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(color: selectedType == 'Income' ? Colors.white : Colors.grey),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = 'Income');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: "Nama Tagihan",
                      labelStyle: GoogleFonts.nunito(color: Colors.grey),
                      hintText: "Contoh: Netflix, WiFi, Indihome, Kost",
                      hintStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: "Nominal",
                      labelStyle: GoogleFonts.nunito(color: Colors.grey),
                      prefixText: "Rp ",
                      prefixStyle: GoogleFonts.nunito(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Kategori
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      labelStyle: GoogleFonts.nunito(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _billCategories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.nunito()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Wallet
                  DropdownButtonFormField<String>(
                    initialValue: selectedWallet,
                    style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: "Potong Saldo Dari",
                      labelStyle: GoogleFonts.nunito(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: wallets.map((w) {
                      return DropdownMenuItem(value: w.name, child: Text(w.name, style: GoogleFonts.nunito()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedWallet = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Frequency
                  DropdownButtonFormField<String>(
                    initialValue: selectedFreq,
                    style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: "Frekuensi Pengulangan",
                      labelStyle: GoogleFonts.nunito(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _frequencies.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.nunito()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedFreq = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date Picker
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade400, width: 0.8),
                    ),
                    title: Text(
                      "Tanggal Jatuh Tempo Berikutnya",
                      style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey),
                    ),
                    subtitle: Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate),
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    trailing: const Icon(Icons.calendar_month_outlined, color: AppColors.primaryBlue),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
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
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    SipekaNotification.showWarning(context, "Nama tagihan tidak boleh kosong!");
                    return;
                  }
                  final cleanAmount = amountController.text.replaceAll('.', '');
                  final amount = double.tryParse(cleanAmount) ?? 0.0;
                  if (amount <= 0) {
                    SipekaNotification.showWarning(context, "Nominal harus diisi dengan benar!");
                    return;
                  }

                  final title = titleController.text.trim();
                  final frequency = _frequenciesDb[_frequencies.indexOf(selectedFreq)];

                  final billProvider = Provider.of<BillProvider>(context, listen: false);
                  Navigator.pop(ctx);

                  bool success;
                  if (existingBill == null) {
                    final newId = const Uuid().v4();
                    final newBill = BillEntity(
                      id: newId,
                      title: title,
                      amount: amount,
                      type: selectedType,
                      category: selectedCategory,
                      wallet: selectedWallet,
                      frequency: frequency,
                      startDate: DateTime.now(),
                      nextExecutionDate: selectedDate,
                      isActive: true,
                      remindMe: true,
                    );
                    success = await billProvider.addBill(newBill);
                  } else {
                    final updatedBill = BillEntity(
                      id: existingBill.id,
                      title: title,
                      amount: amount,
                      type: selectedType,
                      category: selectedCategory,
                      wallet: selectedWallet,
                      frequency: frequency,
                      startDate: existingBill.startDate,
                      lastExecutedDate: existingBill.lastExecutedDate,
                      nextExecutionDate: selectedDate,
                      isActive: existingBill.isActive,
                      remindMe: existingBill.remindMe,
                    );
                    success = await billProvider.updateBill(updatedBill);
                  }

                  if (context.mounted) {
                    if (success) {
                      SipekaNotification.showSuccess(
                        context,
                        existingBill == null ? "Tagihan rutin berhasil dibuat!" : "Tagihan rutin berhasil diperbarui!",
                      );
                    } else {
                      SipekaNotification.showWarning(context, "Terjadi kesalahan saat menyimpan tagihan rutin.");
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
}
