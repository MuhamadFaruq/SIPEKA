import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';

class DebtHistoryScreen extends StatelessWidget {
  const DebtHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DebtProvider>(context);
    // Cek apakah mode gelap sedang aktif
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Ambil hanya yang sudah lunas
    final historyList = provider.debts.where((d) => d.isPaid).toList();

    return Scaffold(
      // --- FIX: Background dinamis ---
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Histori Pelunasan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF00479E)]),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: historyList.isEmpty
          ? Center(child: Text("Belum ada histori pelunasan", style: GoogleFonts.nunito(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final debt = historyList[index];
                final isHutang = debt.type == 'Borrowed';

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // --- FIX: Warna kartu dinamis ---
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[400], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(debt.name, style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyLarge?.color // FIX: Warna teks judul
                                )),
                                Text(isHutang ? "Saya berhutang" : "Orang berhutang", 
                                  style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(debt.amount),
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold, 
                              color: Theme.of(context).textTheme.bodyLarge?.color // FIX: Warna nominal
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDateInfo(context, "Tgl Pinjam", debt.date), // Tambah context
                          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                          _buildDateInfo(context, "Tgl Lunas", debt.paidDate ?? DateTime.now()), // Tambah context
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDateInfo(BuildContext context, String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey)),
        Text(
          DateFormat('d MMM yyyy', 'id_ID').format(date), 
          style: GoogleFonts.nunito(
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color // FIX: Warna teks tanggal
          ),
        ),
      ],
    );
  }
}