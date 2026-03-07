import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../utils/formatters.dart'; // Pastikan CurrencyInputFormatter ada di sini

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  // Data Model (Gunakan double untuk nominal agar akurat)
  final List<Map<String, dynamic>> _wishlistItems = [];

  // Helper tampilan mata uang
  String formatRupiah(double number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  // --- LOGIC 1: MENABUNG ---
  void _showNabungDialog(BuildContext context, int id) {
    final item = _wishlistItems.firstWhere((e) => e['id'] == id);
    final nominalController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE9E9E9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 25, left: 20, right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tabung: ${item['title']}", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Terkumpul: ${formatRupiah(item['collected'])}", style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: nominalController,
                keyboardType: TextInputType.number, // Paksa keyboard angka
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Hanya izinkan digit
                  CurrencyInputFormatter(), // Format titik otomatis dari utils/formatters.dart
                ],
                decoration: InputDecoration(
                  labelText: 'Nominal Tabungan',
                  filled: true,
                  fillColor: Colors.white,
                  prefixText: "Rp ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue]), borderRadius: BorderRadius.circular(12)),
                  child: ElevatedButton(
                    onPressed: () {
                      // Membersihkan titik sebelum parse ke double
                      String cleanValue = nominalController.text.replaceAll('.', '');
                      double nominal = double.tryParse(cleanValue) ?? 0;
                      
                      if (nominal > 0) {
                        setState(() { item['collected'] += nominal; });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: Text("Simpan Tabungan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC 2: TAMBAH/EDIT ---
  void _showEditDialog(BuildContext context, int? id) {
    bool isEdit = id != null;
    Map<String, dynamic>? item;
    final titleController = TextEditingController();
    final targetController = TextEditingController();

    if (isEdit) {
      item = _wishlistItems.firstWhere((e) => e['id'] == id);
      titleController.text = item['title'];
      // Format nominal awal saat edit agar muncul titiknya
      targetController.text = NumberFormat.decimalPattern('id').format(item['target']);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE9E9E9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 25, left: 20, right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Impian' : 'Tambah Impian Baru', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Nama Barang',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Target Harga (Rp)',
                  filled: true,
                  fillColor: Colors.white,
                  prefixText: "Rp ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue]), borderRadius: BorderRadius.circular(12)),
                  child: ElevatedButton(
                    onPressed: () {
                      String cleanValue = targetController.text.replaceAll('.', '');
                      double target = double.tryParse(cleanValue) ?? 0;
                      
                      if (titleController.text.isNotEmpty && target > 0) {
                        setState(() {
                          if (isEdit) {
                            item!['title'] = titleController.text;
                            item['target'] = target;
                          } else {
                            _wishlistItems.add({
                              'id': DateTime.now().millisecondsSinceEpoch,
                              'title': titleController.text,
                              'target': target,
                              'collected': 0.0,
                              'icon': Icons.stars,
                              'color': startBlue,
                            });
                          }
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: Text("Simpan Impian", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC 3: HAPUS DENGAN DESAIN CLEAN (IDENTIK MENU ANGGARAN) ---
  // --- LOGIC 3: HAPUS DENGAN TAMPILAN IDENTIK MENU ANGGARAN ---
  void _deleteItem(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus?"),
        actions: [
          // Tombol BATAL
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("BATAL")
          ),
          // Tombol HAPUS dengan gaya ElevatedButton agar sama persis
          ElevatedButton(
            onPressed: () {
              setState(() { 
                // Logika hapus untuk Wishlist
                _wishlistItems.removeWhere((item) => item['id'] == id); 
              });
              Navigator.pop(ctx);
            },
            child: const Text("HAPUS")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalTerkumpul = _wishlistItems.fold(0.0, (sum, item) => sum + (item['collected'] as double));
    double totalTarget = _wishlistItems.fold(0.0, (sum, item) => sum + (item['target'] as double));

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity, height: 220,
                  padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [startBlue, endBlue]),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Wishlist Tabungan", style: GoogleFonts.nunito(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text("Nabung dikit-dikit jadi bukit!", style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Positioned(
                  top: 130, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Tabungan", style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: Colors.black54)),
                        Text(formatRupiah(totalTerkumpul), style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue]), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Target Total", style: GoogleFonts.nunito(color: Colors.white70, fontSize: 12)),
                              Text(formatRupiah(totalTarget), style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),

            // SECTION TITLE & BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Target Nabung", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue]), borderRadius: BorderRadius.circular(20)),
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditDialog(context, null),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: Text("Tambah", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                    ),
                  )
                ],
              ),
            ),

            // LIST ITEMS
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wishlistItems.length,
              itemBuilder: (context, index) {
                final item = _wishlistItems[index];
                double progress = (item['collected'] / item['target']).clamp(0.0, 1.0);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: item['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(item['icon'], color: item['color'], size: 28),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'], style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Target: ${formatRupiah(item['target'])}", style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 11)),
                              ],
                            ),
                          ),
                          Text("${(progress * 100).toInt()}%", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: Colors.grey[100], valueColor: AlwaysStoppedAnimation<Color>(startBlue)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue]), borderRadius: BorderRadius.circular(12)),
                              child: ElevatedButton(
                                onPressed: () => _showNabungDialog(context, item['id']),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                                child: Text("Tabung sisa receh", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildActionBtn(Icons.edit, Colors.grey[200]!, Colors.black54, () => _showEditDialog(context, item['id'])),
                          const SizedBox(width: 8),
                          _buildActionBtn(Icons.close, Colors.red[50]!, Colors.red, () => _deleteItem(item['id'])),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color bg, Color iconCol, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconCol, size: 20),
      ),
    );
  }
}