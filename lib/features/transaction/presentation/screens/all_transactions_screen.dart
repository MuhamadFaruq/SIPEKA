import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';
import 'package:sipeka/core/constants/constants.dart'; 
import 'package:sipeka/core/services/notifications.dart'; 
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/wallet/domain/entities/wallet_entity.dart'; 
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/core/utils/formatters.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  // Advanced filter states
  String _selectedType = "Semua Tipe";
  String _selectedWallet = "Semua Sumber";
  String _selectedCategory = "Semua Kategori";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final walletNames = walletProvider.wallets.map((w) => w.name).toList();
    if (_selectedWallet != "Semua Sumber" && !walletNames.contains(_selectedWallet)) {
      _selectedWallet = "Semua Sumber";
    }
    
    // Kategori disesuaikan dengan tipe yang dipilih
    final List<String> allCategories = provider.transactions
        .where((tx) {
          if (_selectedType == "Pemasukan") return tx.type == TransactionType.income;
          if (_selectedType == "Pengeluaran") return tx.type == TransactionType.expense;
          return true; // Semua Tipe
        })
        .map((tx) => tx.category)
        .toSet()
        .toList();

    final List<Transaction> filteredTransactions = provider.getFilteredTransactions(
      query: _searchQuery,
      dateRange: _selectedDateRange,
      category: _selectedCategory == "Semua Kategori" ? "Semua" : _selectedCategory,
      wallet: _selectedWallet == "Semua Sumber" ? "Semua" : _selectedWallet,
      type: _selectedType == "Semua Tipe" ? "Semua" : _selectedType,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          "Semua Transaksi",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            tooltip: "Ekspor CSV",
            onPressed: () => _exportToCSV(context, filteredTransactions),
          ),
          if (_selectedDateRange != null || 
              _searchQuery.isNotEmpty || 
              _selectedType != "Semua Tipe" || 
              _selectedWallet != "Semua Sumber" || 
              _selectedCategory != "Semua Kategori")
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Reset Filter",
              onPressed: () => setState(() {
                _searchQuery = "";
                _selectedDateRange = null;
                _selectedType = "Semua Tipe";
                _selectedWallet = "Semua Sumber";
                _selectedCategory = "Semua Kategori";
                _searchController.clear(); 
              }),
            ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF007AFF), Color(0xFF00479E)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(context, allCategories),
          Expanded(
            child: filteredTransactions.isEmpty
                ? (_searchQuery.isNotEmpty || 
                   _selectedDateRange != null || 
                   _selectedType != "Semua Tipe" || 
                   _selectedWallet != "Semua Sumber" || 
                   _selectedCategory != "Semua Kategori"
                    ? _buildSearchNotFoundState() 
                    : _buildEmptyState())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      return InkWell(
                        onLongPress: () => _showTransactionOptions(context, tx),
                        child: _buildTransactionCard(context, tx),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context, List<String> allCategories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletNames = Provider.of<WalletProvider>(context).wallets.map((w) => w.name).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController, 
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "Cari transaksi...",
                      hintStyle: GoogleFonts.nunito(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _searchQuery = "";
                              _searchController.clear(); 
                            }),
                          ) 
                        : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _showDateFilter,
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: _selectedDateRange != null ? const Color(0xFF007AFF) : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterDropdown(
                  value: _selectedType,
                  items: ["Semua Tipe", "Pemasukan", "Pengeluaran"],
                  onChanged: (val) => setState(() {
                    _selectedType = val!;
                    // Reset kategori agar tidak ada kategori yang salah tipe
                    _selectedCategory = "Semua Kategori";
                  }),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  value: _selectedWallet,
                  items: ["Semua Sumber", ...walletNames],
                  onChanged: (val) => setState(() => _selectedWallet = val!),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  value: _selectedCategory,
                  items: ["Semua Kategori", ...allCategories],
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaction tx) {
    bool isExpense = tx.type == TransactionType.expense;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10), 
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02), 
            blurRadius: 5
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), 
            decoration: BoxDecoration(
              color: isExpense 
                ? Colors.red.withOpacity(0.1) 
                : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.getIcon(tx.category),
              size: 20, 
              color: isExpense ? Colors.red[400] : Colors.green[400],
            ),
          ),
          const SizedBox(width: 15),
          // Di dalam widget _buildTransactionCard, bagian Expanded Column:
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color
                )),
                Row(
                  children: [
                    Text(tx.category, style: GoogleFonts.nunito(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), 
                      fontSize: 11
                    )),
                    const SizedBox(width: 8),
                    // --- TAMBAHAN BADGE SUMBER ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getSourceColor(tx.source).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getSourceColor(tx.source).withOpacity(0.2), width: 0.5)
                      ),
                      child: Text(
                        tx.source.toUpperCase(),
                        style: GoogleFonts.nunito(
                          fontSize: 7, 
                          fontWeight: FontWeight.bold, 
                          color: _getSourceColor(tx.source)
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(tx.date),
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
          // --- BAGIAN NOMINAL & KETERANGAN DOMPET ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(tx.amount)}",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, 
                  color: isExpense ? Colors.red[400] : Colors.green[400],
                ),
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final walletProv = Provider.of<WalletProvider>(context, listen: false);
                  final wallet = walletProv.wallets.firstWhere(
                    (w) => w.name.toLowerCase() == tx.wallet.toLowerCase(),
                    orElse: () => const WalletEntity(id: '', name: '', initialBalance: 0, iconCode: 0, colorHex: '#9E9E9E'),
                  );
                  final walletColor = Color(int.parse(wallet.colorHex.replaceFirst('#', '0xFF')));
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: walletColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tx.wallet.toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: walletColor,
                          ),
                        ),
                        if (wallet.isShared) ...[
                          const SizedBox(width: 3),
                          Icon(Icons.cloud_done_rounded, size: 10, color: walletColor),
                        ],
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LOGIKA HELPER ---

  Widget _buildSearchNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "Transaksi tidak ditemukan",
            style: GoogleFonts.nunito(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          Text(
            "Coba kata kunci lain atau reset filter.",
            style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 15),
          Text("Belum ada riwayat transaksi", style: GoogleFonts.nunito(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _showDateFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF007AFF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  void _showTransactionOptions(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tx.title,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(tx.amount),
                  style: GoogleFonts.nunito(
                    color: tx.type == TransactionType.expense ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFF007AFF)),
                  ),
                  title: Text("Edit Transaksi", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                  subtitle: Text("Ubah detail transaksi ini", style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditTransactionSheet(context, tx);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.red),
                  ),
                  title: Text("Hapus Transaksi", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                  subtitle: Text("Hapus catatan ini secara permanen", style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context, tx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditTransactionSheet(BuildContext context, Transaction tx) {
    final titleController = TextEditingController(text: tx.title);
    final amountController = TextEditingController(
      text: NumberFormat('#,###', 'id_ID').format(tx.amount),
    );
    
    String selectedType = tx.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran';
    String selectedCategory = tx.category;
    String selectedWallet = tx.wallet;
    DateTime selectedDate = tx.date;

    final wallets = Provider.of<WalletProvider>(context, listen: false).wallets;
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stateCtx, setSheetState) {
            // Build category list based on type
            List<String> categories = [];
            if (selectedType == 'Pengeluaran') {
              categories = budgetProvider.budgets.map((b) => b.category).toList();
            } else {
              categories = ['Gaji', 'Hadiah', 'Bonus', 'Penjualan', 'Transfer', 'Lainnya'];
            }
            // Ensure current category is in list
            if (!categories.contains(selectedCategory)) {
              categories.add(selectedCategory);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        "Edit Transaksi",
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tipe selector
                      Text("Tipe", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: ['Pengeluaran', 'Pemasukan'].map((type) {
                            final isSelected = selectedType == type;
                            final color = type == 'Pengeluaran' ? Colors.red : Colors.green;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() {
                                  selectedType = type;
                                  // Reset category when switching type
                                  if (type == 'Pengeluaran') {
                                    final cats = budgetProvider.budgets.map((b) => b.category).toList();
                                    selectedCategory = cats.isNotEmpty ? cats.first : tx.category;
                                  } else {
                                    selectedCategory = 'Gaji';
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    type,
                                    style: GoogleFonts.nunito(
                                      color: isSelected ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Judul
                      Text("Judul", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nominal
                      Text("Nominal", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          prefixText: "Rp ",
                          prefixStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kategori
                      Text("Kategori", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).cardColor,
                            style: GoogleFonts.nunito(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 14,
                            ),
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(AppIcons.getIcon(cat), size: 18, color: const Color(0xFF007AFF)),
                                    const SizedBox(width: 8),
                                    Text(cat, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dompet
                      if (wallets.isNotEmpty) ...[
                        Text("Dompet", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: wallets.any((w) => w.name.toLowerCase() == selectedWallet.toLowerCase())
                                  ? selectedWallet
                                  : wallets.first.name,
                              isExpanded: true,
                              dropdownColor: Theme.of(context).cardColor,
                              style: GoogleFonts.nunito(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 14,
                              ),
                              items: wallets.map((w) {
                                return DropdownMenuItem(
                                  value: w.name,
                                  child: Text(w.name, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setSheetState(() => selectedWallet = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tanggal
                      Text("Tanggal", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF007AFF)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF007AFF)),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate),
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF007AFF), Color(0xFF00479E)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              String cleanAmount = amountController.text.replaceAll('.', '');
                              double amount = double.tryParse(cleanAmount) ?? 0;

                              if (titleController.text.isEmpty) {
                                SipekaNotification.showWarning(context, "Judul tidak boleh kosong!");
                                return;
                              }
                              if (amount <= 0) {
                                SipekaNotification.showWarning(context, "Nominal harus lebih dari 0!");
                                return;
                              }

                              final updatedTx = Transaction(
                                id: tx.id,
                                title: titleController.text,
                                amount: amount,
                                date: selectedDate,
                                type: selectedType == 'Pengeluaran' ? TransactionType.expense : TransactionType.income,
                                category: selectedCategory,
                                wallet: selectedWallet,
                                source: tx.source,
                              );

                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );

                              final txProvider = Provider.of<TransactionProvider>(context, listen: false);
                              final success = await txProvider.updateTransaction(updatedTx);

                              if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading
                              if (ctx.mounted) Navigator.pop(ctx); // close bottom sheet

                              if (context.mounted) {
                                if (success) {
                                  SipekaNotification.showSuccess(context, "Transaksi berhasil diperbarui!");
                                } else {
                                  SipekaNotification.showWarning(context, "Gagal memperbarui transaksi.");
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "SIMPAN PERUBAHAN",
                              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Hapus Transaksi?", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: Text("Yakin ingin menghapus catatan '${tx.title}'?", style: GoogleFonts.nunito()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(tx.id);
                Navigator.pop(ctx);
              },
              child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Letakkan ini di bagian bawah class _AllTransactionsScreenState
  Color _getSourceColor(String? source) {
    // Pakai lowercase supaya pengecekan lebih aman (case-insensitive)
    switch (source?.toLowerCase()) {
      case 'voice command':
        return Colors.purple;
      case 'ocr scan':
        return Colors.orange;
      case 'jalan pintas':
        return Colors.teal;
      case 'manual':
        return Colors.blueGrey;
      case 'shared':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFiltered = !value.startsWith("Semua");
    
    return PopupMenuButton<String>(
      initialValue: value,
      tooltip: "Pilih Filter",
      offset: const Offset(0, 32), // Pushes the popup menu below the button
      onSelected: (val) => onChanged(val),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (BuildContext context) {
        return items.map((String item) {
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Text(
              item,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: item == value
                    ? const Color(0xFF007AFF)
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: item == value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFiltered ? const Color(0xFF007AFF) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.nunito(
                color: isFiltered 
                    ? const Color(0xFF007AFF) 
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isFiltered ? const Color(0xFF007AFF) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context, List<Transaction> txList) async {
    if (txList.isEmpty) {
      SipekaNotification.showWarning(context, "Tidak ada data transaksi untuk diekspor.");
      return;
    }

    try {
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add(["ID", "Tanggal", "Kategori", "Catatan/Judul", "Tipe", "Nominal", "Dompet/Wallet", "Sumber Input"]);
      
      // Data
      for (var tx in txList) {
        rows.add([
          tx.id,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.date),
          tx.category,
          tx.title,
          tx.type == TransactionType.income ? "Pemasukan" : "Pengeluaran",
          tx.amount,
          tx.wallet,
          tx.source,
        ]);
      }
      
      String csvData = const ListToCsvConverter().convert(rows);
      
      final directory = await getTemporaryDirectory();
      final String path = "${directory.path}/sipeka_transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv";
      final File file = File(path);
      await file.writeAsString(csvData);
      
      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'Ekspor Riwayat Transaksi SIPEKA',
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal mengekspor CSV: $e");
      if (context.mounted) {
        SipekaNotification.showWarning(context, "Gagal mengekspor data.");
      }
    }
  }
}