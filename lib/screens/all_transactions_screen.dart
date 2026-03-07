import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Mengambil data transaksi dari provider
    final provider = Provider.of<TransactionProvider>(context);
    
    // 2. Mengurutkan data berdasarkan tanggal terbaru
    final List<Transaction> transactions = List<Transaction>.from(provider.transactions);
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      // WARNA BACKGROUND: Abu-abu muda agar kotak putih terlihat kontras
      backgroundColor: const Color(0xFFE9E9E9), 
      appBar: AppBar(
        // Menghapus bayangan standar
        elevation: 0,
        // Tombol kembali warna putih agar kontras dengan gradasi biru
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
        // --- LOGIKA GRADASI PADA HEADER ---
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF007AFF), // Biru Terang
                Color(0xFF00479E), // Biru Gelap
              ],
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
                return _buildTransactionCard(tx);
              },
            ),
    );
  }

  // --- WIDGET KARTU TRANSAKSI (KOTAK PUTIH RAMPING) ---
  // --- WIDGET KARTU TRANSAKSI (GAYA 3 BARIS RAMPING) ---
  Widget _buildTransactionCard(Transaction tx) {
    bool isExpense = tx.type == 'Expense';

    return Container(
      margin: const EdgeInsets.only(bottom: 10), 
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: Colors.white, // Kotak Putih (FFFFFF) sesuai tema baru
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
          // 1. Indikator Ikon Kecil
          Container(
            padding: const EdgeInsets.all(6), 
            decoration: BoxDecoration(
              color: isExpense ? Colors.red[50] : Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
              size: 16, 
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(width: 15),

          // 2. Kolom Informasi (3 Baris)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Baris 1: Judul & Sumber Dana
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
                    // Ikon Sumber Dana (Biru 007AFF)
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
                const SizedBox(height: 2),

                // Baris 2: Kategori
                Text(
                  tx.category,
                  style: GoogleFonts.nunito(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),

                // Baris 3: Tanggal & Waktu Lengkap
                Text(
                  DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(tx.date),
                  style: GoogleFonts.nunito(
                    color: Colors.grey,
                    fontSize: 10, 
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 3. Nominal Keuangan
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

  // Tampilan jika data masih kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 15),
          Text(
            "Belum ada riwayat transaksi",
            style: GoogleFonts.nunito(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}