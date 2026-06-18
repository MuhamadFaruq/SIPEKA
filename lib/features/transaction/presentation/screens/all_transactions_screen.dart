import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart'; 

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    final List<Transaction> filteredTransactions = provider.getFilteredTransactions(
      query: _searchQuery,
      dateRange: _selectedDateRange,
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
          if (_selectedDateRange != null || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {
                _searchQuery = "";
                _selectedDateRange = null;
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
          _buildSearchAndFilterBar(context),
          Expanded(
            child: filteredTransactions.isEmpty
                ? (_searchQuery.isNotEmpty || _selectedDateRange != null 
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

  Widget _buildSearchAndFilterBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      color: Theme.of(context).cardColor,
      child: Row(
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
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaction tx) {
    bool isExpense = tx.type == 'Expense' || tx.type == 'Pengeluaran';
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
}