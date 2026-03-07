import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Import Provider
import '../providers/transaction_provider.dart';
import '../providers/quick_action_provider.dart';
import '../providers/budget_provider.dart'; // Import Baru

// Import Model
import '../models/transaction_model.dart';
import '../models/quick_action_model.dart';

// Import Screen
import 'all_transactions_screen.dart';
import 'settings_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // --- LOGIC: DIALOG TAMBAH JALAN PINTAS DINAMIS ---
  void _showAddShortcutDialog() {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final quickActionProvider = Provider.of<QuickActionProvider>(context, listen: false);
    
    // Ambil daftar nama kategori dari anggaran
    List<String> daftarAnggaran = budgetProvider.budgets.map((b) => b.category).toList();

    if (daftarAnggaran.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Anggaran Kosong", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: Text("Buat anggaran dulu di menu Anggaran sebelum menambah jalan pintas ya!", style: GoogleFonts.nunito()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    String? selectedKategori;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE9E9E9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 25, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tambah Jalan Pintas", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Dropdown Kategori dari Anggaran
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text("Pilih Kategori Anggaran", style: GoogleFonts.nunito()),
                        value: selectedKategori,
                        items: daftarAnggaran.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: GoogleFonts.nunito()),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedKategori = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Input Nominal Cepat
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Nominal Transaksi Cepat",
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
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF00479E)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () {
                          double amt = double.tryParse(amountController.text) ?? 0;
                          if (selectedKategori != null && amt > 0) {
                            // Ambil ikon dari budget yang dipilih
                            int iconCode = budgetProvider.budgets.firstWhere((b) => b.category == selectedKategori).iconCode;
                            
                            quickActionProvider.addAction(QuickAction(
                              id: DateTime.now().toString(),
                              label: selectedKategori!,
                              category: selectedKategori!,
                              amount: amt,
                              icon: IconData(iconCode, fontFamily: 'MaterialIcons'),
                            ));
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text("SIMPAN JALAN PINTAS", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    final List<Transaction> sortedTransactions = List<Transaction>.from(provider.transactions);
    sortedTransactions.sort((a, b) => b.date.compareTo(a.date));

    double dompetBalance = _calculateBalance(sortedTransactions, 'Dompet');
    double eWalletBalance = _calculateBalance(sortedTransactions, 'E-Wallet');
    double totalBalance = dompetBalance + eWalletBalance;

    String financialStatus = totalBalance < 500000 ? "Tanggal Tua Nih - Irit Dulu Ya!" : "Aman, Masih Bisa Jajan!";
    Color statusColor = totalBalance < 500000 ? const Color(0xFFFF5252) : const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF007AFF), Color(0xFF00479E)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hallo Faruq", style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Duitmu Aman Kok", style: GoogleFonts.nunito(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                        }, 
                        icon: const Icon(Icons.more_vert, color: Colors.white)
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(financialStatus, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildBalanceCard("Dompet", dompetBalance, isNegative: dompetBalance < 0),
                      const SizedBox(width: 15),
                      _buildBalanceCard("E-Wallet", eWalletBalance, isNegative: eWalletBalance < 0),
                    ],
                  ),
                ],
              ),
            ),

            // --- JALAN PINTAS ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Jalan Pintas", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _showAddShortcutDialog, 
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF007AFF), size: 20)
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  Consumer<QuickActionProvider>(
                    builder: (context, actionProvider, child) {
                      if (actionProvider.actions.isEmpty) {
                        return Center(child: Text("Belum ada pintasan", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)));
                      }
                      
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: actionProvider.actions.map((action) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 25), 
                              child: _buildShortcutIcon(
                                context, 
                                action.icon, 
                                action.label, 
                                const Color(0xFF007AFF), 
                                action.category, 
                                action.amount,
                                action.id, // Tambah ID untuk hapus
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- TRANSAKSI TERBARU ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Transaksi Terbaru", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AllTransactionsScreen()));
                        },
                        child: Text("Lihat Semua >", style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF007AFF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  sortedTransactions.isEmpty 
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text("Belum ada data", style: GoogleFonts.nunito(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedTransactions.length > 5 ? 5 : sortedTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(sortedTransactions[index]);
                      },
                    ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildTransactionItem(Transaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF007AFF).withOpacity(0.07), shape: BoxShape.circle),
            child: Icon(_getCategoryIcon(tx.category), size: 20, color: const Color(0xFF007AFF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(tx.category, style: GoogleFonts.nunito(color: Colors.black54, fontSize: 11)),
              ],
            ),
          ),
          Text(
            "${tx.type == 'Expense' ? '-' : '+'}${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(tx.amount)}",
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold, fontSize: 15,
              color: tx.type == 'Expense' ? const Color(0xFFFF5252) : const Color(0xFF00C853),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    // Bisa disesuaikan dengan logic ikon dinamis anggaran jika perlu
    return Icons.monetization_on;
  }

  double _calculateBalance(List<Transaction> transactions, String walletName) {
    double income = 0;
    double expense = 0;
    for (var tx in transactions) {
      if (tx.wallet == walletName) {
        if (tx.type == 'Income' || tx.type == 'Pemasukan') {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
    }
    return income - expense;
  }

  Widget _buildBalanceCard(String title, double amount, {bool isNegative = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
              style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.bold, color: isNegative ? Colors.red : Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutIcon(BuildContext context, IconData icon, String label, Color color, String category, double amount, String id) {
    return GestureDetector(
      onTap: () => _showConfirmationDialog(context, label, category, amount, icon),
      onLongPress: () {
        // Logika hapus jalan pintas
        Provider.of<QuickActionProvider>(context, listen: false).removeAction(id);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
            child: Icon(icon, color: const Color(0xFF007AFF), size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String label, String category, double amount, IconData icon) {
    String formattedAmount = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [Icon(icon, color: const Color(0xFF007AFF)), const SizedBox(width: 10), Text("Konfirmasi", style: GoogleFonts.nunito(fontWeight: FontWeight.bold))]),
          content: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Simpan transaksi ini?", style: GoogleFonts.nunito(color: Colors.grey)),
              const SizedBox(height: 10),
              Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(formattedAmount, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFF5252))),
              const SizedBox(height: 5),
              Text("Dompet • $category", style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final newTx = Transaction(
                  id: DateTime.now().toString(), 
                  title: label, 
                  amount: amount, 
                  date: DateTime.now(), 
                  type: 'Expense', 
                  category: category, 
                  wallet: 'Dompet'
                );
                Provider.of<TransactionProvider>(context, listen: false).addTransaction(newTx);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Berhasil simpan $label"), backgroundColor: Colors.green)
                );
              },
              child: const Text("Ya, Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }
}