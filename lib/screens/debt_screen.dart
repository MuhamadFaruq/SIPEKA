import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../models/debt_model.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  bool _isHutangMode = false; 

  // Definisi warna gradasi agar konsisten
  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DebtProvider>(context);
    
    final displayedList = provider.debts.where((d) {
      return _isHutangMode ? d.type == 'Borrowed' : d.type == 'Lent';
    }).toList();

    final Color themeColor = _isHutangMode ? const Color(0xFFFF5252) : const Color(0xFF00C853);
    final String titleText = _isHutangMode ? "Total Hutang" : "Total Piutang";
    final double totalAmount = _isHutangMode ? provider.totalHutang : provider.totalPiutang;

    return Scaffold(
      // PERUBAHAN: Background halaman menjadi E9E9E9
      backgroundColor: const Color(0xFFE9E9E9),
      appBar: AppBar(
        // PERUBAHAN: AppBar menggunakan gradasi biru
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startBlue, endBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Catatan Hutang", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Kelola hutang piutang kamu", style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              // PERUBAHAN: Header body menggunakan gradasi biru
              gradient: LinearGradient(
                colors: [startBlue, endBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, // KOTAK PUTIH
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titleText, style: GoogleFonts.nunito(color: Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalAmount),
                        style: GoogleFonts.nunito(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold, 
                          color: themeColor 
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("Orang hutang ke saya", !_isHutangMode),
                      _buildTabButton("Saya hutang ke orang", _isHutangMode),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isHutangMode ? "Daftar Hutang" : "Daftar Piutang",
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // PERUBAHAN: Tombol Tambah menggunakan gradasi biru
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [startBlue, endBlue]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _showDebtDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Tambah"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: displayedList.length,
              itemBuilder: (context, index) {
                final debt = displayedList[index];
                return _buildDebtCard(debt, themeColor);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isHutangMode = text == "Saya hutang ke orang";
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // PERUBAHAN: Tab aktif menggunakan gradasi biru (startBlue)
            color: isActive ? startBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isActive ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtCard(Debt debt, Color color) {
    return InkWell(
      onLongPress: () => _confirmDelete(context, debt.id),
      onTap: () => _showDebtDialog(context, debt: debt),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // KOTAK PUTIH
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              // PERUBAHAN: Avatar menggunakan gradasi/warna biru tema
              backgroundColor: startBlue,
              child: Text(
                debt.name.isNotEmpty ? debt.name.substring(0, 1).toUpperCase() : "?",
                style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debt.name, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(debt.date),
                    style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              "${_isHutangMode ? '-' : '+'}${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(debt.amount)}",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold, 
                fontSize: 16, 
                color: color
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDebtDialog(BuildContext context, {Debt? debt}) {
    final bool isEdit = debt != null;
    final nameController = TextEditingController(text: isEdit ? debt.name : "");
    
    String initialAmount = "";
    if (isEdit) {
      initialAmount = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(debt.amount);
    }
    final amountController = TextEditingController(text: initialAmount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE9E9E9), // PERUBAHAN: Background BottomSheet
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? "Edit Catatan" : "Tambah Catatan Baru", 
                  style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nama Orang / Toko",
                  filled: true,
                  fillColor: Colors.white, // KOTAK PUTIH
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Nominal (Rp)",
                  filled: true,
                  fillColor: Colors.white, // KOTAK PUTIH
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                    double? parsedValue = double.tryParse(cleanValue);
                    if (parsedValue != null) {
                      String formatted = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(parsedValue);
                      amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    // PERUBAHAN: Tombol Simpan menggunakan gradasi
                    gradient: LinearGradient(colors: [startBlue, endBlue]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                        final provider = Provider.of<DebtProvider>(context, listen: false);
                        double cleanAmount = double.tryParse(amountController.text.replaceAll('.', '')) ?? 0;

                        if (isEdit) {
                          provider.updateDebt(debt.id, nameController.text, cleanAmount);
                        } else {
                          final newDebt = Debt(
                            id: DateTime.now().toString(),
                            name: nameController.text,
                            amount: cleanAmount,
                            date: DateTime.now(),
                            type: _isHutangMode ? 'Borrowed' : 'Lent',
                          );
                          provider.addDebt(newDebt);
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: Text(isEdit ? "PERBARUI" : "SIMPAN", 
                        style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.red.shade100),
                      ),
                    ),
                    onPressed: () {
                      _confirmDelete(context, debt.id);
                    },
                    child: Text(
                      "HAPUS CATATAN",
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white, // KOTAK PUTIH
          title: Text(
            "Hapus Catatan?",
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Data ini akan dihapus permanen. Kamu yakin ingin melanjutkan?",
            style: GoogleFonts.nunito(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Provider.of<DebtProvider>(context, listen: false).deleteDebt(id);
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Catatan berhasil dihapus")),
                );
              },
              child: const Text("YA, HAPUS", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}