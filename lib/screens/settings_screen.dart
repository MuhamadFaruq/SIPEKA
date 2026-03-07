import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; 

// Import Utilities & Provider
import '../utils/formatters.dart'; 
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/quick_action_provider.dart';
import '../models/quick_action_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9), 
      appBar: AppBar(
        title: Text(
          "Pengaturan",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startBlue, endBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle("Profil"),
          _buildSettingCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: startBlue.withOpacity(0.1),
                child: Icon(Icons.person, color: startBlue),
              ),
              title: Text("Faruq", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              subtitle: Text("Pengguna SIPEKA", style: GoogleFonts.nunito(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEditProfileDialog(context),
            ),
          ),

          const SizedBox(height: 25),

          _buildSectionTitle("Data & Privasi"),
          _buildSettingCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.restore,
                  title: "Reset Semua Data",
                  subtitle: "Menghapus seluruh catatan dari nol",
                  color: Colors.red,
                  onTap: () => _confirmResetData(context),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.cloud_upload_outlined,
                  title: "Ekspor Data",
                  subtitle: "Simpan data ke format CSV",
                  color: Colors.blue,
                  onTap: () => _exportToCSV(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          _buildSectionTitle("Tentang"),
          _buildSettingCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.info_outline,
                  title: "Versi Aplikasi",
                  subtitle: "v1.0.0",
                  color: Colors.grey,
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.star_border,
                  title: "Beri Rating",
                  subtitle: "Dukung kami di Play Store",
                  color: Colors.amber,
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              "SIPEKA © 2026",
              style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageShortcutsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE9E9E9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return Consumer<QuickActionProvider>(
          builder: (context, provider, child) {
            final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Kelola Jalan Pintas", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (provider.actions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text("Belum ada pintasan", style: GoogleFonts.nunito(color: Colors.grey)),
                    )
                  else
                    ...provider.actions.map((action) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: startBlue.withOpacity(0.1), 
                              child: Icon(action.icon, color: startBlue, size: 20)
                            ),
                            title: Text(action.label, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                            subtitle: Text("${currencyFormat.format(action.amount)} • ${action.category}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue), 
                                  onPressed: () => _showAddShortcutForm(context, existingAction: action)
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red), 
                                  // PERBAIKAN: Gunakan removeAction & Tambah Dialog Konfirmasi
                                  onPressed: () => _confirmDeleteShortcut(context, action.id),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: startBlue, 
                        padding: const EdgeInsets.symmetric(vertical: 12), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () => _showAddShortcutForm(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("TAMBAH PINTASAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Tambahkan fungsi konfirmasi hapus gaya "Anggaran"
  void _confirmDeleteShortcut(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: startBlue),
            onPressed: () { 
              Provider.of<QuickActionProvider>(context, listen: false).removeAction(id);
              Navigator.pop(ctx); 
            }, 
            child: const Text("HAPUS", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  void _showAddShortcutForm(BuildContext context, {QuickAction? existingAction}) {
    final nameController = TextEditingController(text: existingAction?.label);
    // Jika edit, tampilkan nominal dengan format titik
    final amountController = TextEditingController(
      text: existingAction != null ? NumberFormat.decimalPattern('id').format(existingAction.amount) : ""
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existingAction == null ? "Pintasan Baru" : "Edit Pintasan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama (Contoh: Parkir)")),
            TextField(
              controller: amountController, 
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Supaya keyboard hanya angka
                CurrencyInputFormatter(), // Supaya otomatis ada titik
              ],
              decoration: const InputDecoration(labelText: "Nominal (Rp)", prefixText: "Rp "),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: startBlue),
            onPressed: () {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final provider = Provider.of<QuickActionProvider>(context, listen: false);
                
                // BERSIHKAN TITIK sebelum dikonversi ke double
                String cleanAmount = amountController.text.replaceAll('.', '');
                double parsedAmount = double.parse(cleanAmount);

                if (existingAction == null) {
                  provider.addAction(QuickAction(
                    id: DateTime.now().toString(), 
                    label: nameController.text, 
                    icon: Icons.flash_on, 
                    category: "Lainnya", 
                    amount: parsedAmount,
                  ));
                } else {
                  provider.updateAction(
                    existingAction.id, 
                    nameController.text, 
                    parsedAmount
                  );
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportToCSV(BuildContext context) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = transactionProvider.transactions;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data transaksi untuk diekspor")));
      return;
    }
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Judul", "Nominal", "Kategori", "Dompet", "Tipe", "Tanggal"]);
    for (var tx in transactions) {
      rows.add([tx.id, tx.title, tx.amount, tx.category, tx.wallet, tx.type, tx.date.toString()]);
    }
    String csvData = const ListToCsvConverter().convert(rows);
    try {
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/laporan_sipeka_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles([XFile(path)], text: 'Laporan Keuangan SIPEKA', sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengekspor data: $e")));
    }
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(left: 5, bottom: 10), child: Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)));
  Widget _buildSettingCard({required Widget child}) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]), child: child);
  Widget _buildListTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) => ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)), title: Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)), subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 11)), onTap: onTap);

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: "Faruq");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Nama Profil", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: TextField(controller: nameController, autofocus: true, decoration: InputDecoration(labelText: "Nama Anda", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: startBlue), onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama profil diperbarui!"))); }, child: const Text("SIMPAN", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Semua Data?", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text("Tindakan ini tidak bisa dibatalkan. Semua transaksi, anggaran, dan hutang akan hilang.", style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Provider.of<TransactionProvider>(context, listen: false).clearAllData(); Provider.of<BudgetProvider>(context, listen: false).clearAllData(); Provider.of<DebtProvider>(context, listen: false).clearAllData(); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil reset ke nol!"))); }, child: const Text("YA, RESET", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}