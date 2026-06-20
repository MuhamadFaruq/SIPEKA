import 'dart:io';
import 'package:flutter/material.dart';
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
    
    // Get all categories dynamically from transaction history
    final List<String> allCategories = provider.transactions
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
                        onLongPress: () => _confirmDelete(context, tx),
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
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  value: _selectedWallet,
                  items: ["Semua Sumber", "Dompet", "E-Wallet"],
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  // Oranye untuk Dompet, Biru untuk E-Wallet
                  color: (tx.wallet == 'Dompet') 
                      ? Colors.orange.withOpacity(0.1) 
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.wallet.toUpperCase(),
                  style: GoogleFonts.nunito(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: (tx.wallet == 'Dompet') ? Colors.orange : Colors.blue,
                  ),
                ),
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
        await Share.shareXFiles([XFile(path)], text: 'Ekspor Riwayat Transaksi SIPEKA');
      }
    } catch (e) {
      debugPrint("Gagal mengekspor CSV: $e");
      if (context.mounted) {
        SipekaNotification.showWarning(context, "Gagal mengekspor data.");
      }
    }
  }
}