import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/formatters.dart'; 
import '../utils/notifications.dart'; 
import '../providers/wishlist_provider.dart';
import '../models/wishlist_model.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  @override
  void initState() {
    super.initState();
    // Memastikan data di-fetch saat layar dibuka
    Future.microtask(() =>
        Provider.of<WishlistProvider>(context, listen: false).fetchAndSetWishlist());
  }

  String formatRupiah(double number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  // --- LOGIC 1: MENABUNG ---
  void _showNabungDialog(BuildContext context, WishlistItem item) {
    final nominalController = TextEditingController();
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tabung buat: ${item.title}", style: GoogleFonts.nunito(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                  )),
                  const SizedBox(height: 10),
                  Text("Terkumpul: ${formatRupiah(item.savedAmount)}", style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nominalController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Nominal Tabungan',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      prefixText: "Rp ",
                      prefixStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
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
                          String cleanValue = nominalController.text.replaceAll('.', '');
                          double nominal = double.tryParse(cleanValue) ?? 0;

                          if (nominal > 0) {
                            // MENGGUNAKAN: addSavings sesuai Provider kamu
                            wishlistProvider.addSavings(item.id, nominal);
                            Navigator.pop(ctx);
                            SipekaNotification.showSuccess(context, "Berhasil menabung ${formatRupiah(nominal)}!");
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: Text("SIMPAN TABUNGAN", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- LOGIC 2: TAMBAH ---
  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target Impian Baru', style: GoogleFonts.nunito(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                  )),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: 'Apa yang ingin dicapai?',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Target Harga (Rp)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      prefixText: "Rp ",
                      prefixStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
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
                            // MENGGUNAKAN: addWishlist dengan parameter WishlistItem
                            wishlistProvider.addWishlist(WishlistItem(
                              id: '', // ID akan digenerate di database
                              title: titleController.text,
                              targetAmount: target,
                              savedAmount: 0.0,
                            ));
                            Navigator.pop(ctx);
                            SipekaNotification.showSuccess(context, "Impian baru ditambahkan!");
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: Text("SIMPAN IMPIAN", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteItem(String id) {
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Impian?", style: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color
        )),
        content: Text("Data tabungan ini akan hilang permanen.", style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              wishlistProvider.deleteWishlist(id);
              Navigator.pop(ctx);
              SipekaNotification.showWarning(context, "Impian telah dihapus.");
            },
            child: const Text("HAPUS")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // MENGGUNAKAN: items dan getter total dari Provider kamu
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlistItems = wishlistProvider.items;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      Text("Pelan tapi pasti, impian jadi nyata!", style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Positioned(
                  top: 130, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20), 
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05), 
                          blurRadius: 10
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tabungan Saat Ini", style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: Colors.grey)),
                        Text(formatRupiah(wishlistProvider.totalSaved), style: GoogleFonts.nunito(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color
                        )),
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue]), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Target", style: GoogleFonts.nunito(color: Colors.white70, fontSize: 11)),
                              Text(formatRupiah(wishlistProvider.totalTarget), style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Daftar Impian", style: GoogleFonts.nunito(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                  )),
                  Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [startBlue, endBlue]), borderRadius: BorderRadius.circular(20)),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: Text("Tambah", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                    ),
                  )
                ],
              ),
            ),

            // LIST ITEMS
            wishlistItems.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wishlistItems.length,
                itemBuilder: (context, index) {
                  final item = wishlistItems[index];
                  double progress = (item.targetAmount == 0 ? 0.0 : item.savedAmount / item.targetAmount).clamp(0.0, 1.0);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02), 
                          blurRadius: 5
                        )
                      ]
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: startBlue.withOpacity(0.1), 
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: Icon(Icons.auto_awesome, color: startBlue, size: 28),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16,
                                    color: Theme.of(context).textTheme.bodyLarge?.color
                                  )),
                                  Text("Target: ${formatRupiah(item.targetAmount)}", style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 11)),
                                ],
                              ),
                            ),
                            Text("${(progress * 100).toInt()}%", style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16, 
                              color: progress >= 1.0 ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress, 
                            minHeight: 7, 
                            backgroundColor: isDark ? Colors.white10 : Colors.grey[100], 
                            valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.green : startBlue)
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: progress >= 1.0 
                                    ? const LinearGradient(colors: [Colors.green, Color(0xFF00C853)]) 
                                    : LinearGradient(colors: [startBlue, endBlue]), 
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: ElevatedButton(
                                  onPressed: progress >= 1.0 ? null : () => _showNabungDialog(context, item),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                                  child: Text(progress >= 1.0 ? "Impian Tercapai! 🎉" : "Tabung Sekarang", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tombol Edit disembunyikan karena Provider belum ada updateWishlist (hanya addSavings)
                            // Jika mau nambah, tinggal buat updateWishlist di Provider
                            const SizedBox(width: 8),
                            _buildActionBtn(context, Icons.delete_outline, isDark ? Colors.red.withOpacity(0.1) : Colors.red[50]!, Colors.red, () => _deleteItem(item.id)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text("Belum ada impian nih.\nYuk tambah sekarang!", 
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, IconData icon, Color bg, Color iconCol, VoidCallback onTap) {
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