import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart'; // Import AppIcons

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    // Data otomatis diambil dari provider (sudah disort di getter provider)
    final List<Transaction> transactions = provider.transactions;

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9), 
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          "Semua Transaksi",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold, 
            fontSize: 18, 
            color: Colors.white
          ),
        ),
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
      body: transactions.isEmpty
          ? _buildEmptyState() 
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                // Tambahkan fitur hapus saat tekan lama
                return InkWell(
                  onLongPress: () => _confirmDelete(context, tx),
                  child: _buildTransactionCard(tx),
                );
              },
            ),
    );
  }

  Widget _buildTransactionCard(Transaction tx) {
    // Penyesuaian logika tipe transaksi agar warna sinkron
    bool isExpense = tx.type == 'Expense' || tx.type == 'Pengeluaran';

    return Container(
      margin: const EdgeInsets.only(bottom: 10), 
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // 1. Ikon Kategori Dinamis (Sesuai Anggaran)
          Container(
            padding: const EdgeInsets.all(8), 
            decoration: BoxDecoration(
              color: isExpense ? Colors.red[50] : Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.getIcon(tx.category), // Gunakan Ikon Kategori
              size: 20, 
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(width: 15),

          // 2. Kolom Informasi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tx.title,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 14, 
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      tx.wallet == 'Dompet' ? Icons.wallet_rounded : Icons.phonelink_ring_rounded,
                      size: 13,
                      color: const Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tx.wallet,
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
                Text(
                  tx.category,
                  style: GoogleFonts.nunito(color: Colors.black54, fontSize: 11),
                ),
                Text(
                  DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(tx.date),
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 3. Nominal
          Text(
            "${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(tx.amount)}",
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 14, 
              color: isExpense ? Colors.red[400] : Colors.green[400],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA HAPUS TRANSAKSI ---
  void _confirmDelete(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Transaksi?"),
        content: Text("Yakin ingin menghapus catatan '${tx.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(tx.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Berhasil dihapus"), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
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
}