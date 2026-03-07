import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'package:flutter/services.dart';
import '../utils/formatters.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  final List<IconData> _availableIcons = [
    Icons.restaurant, 
    Icons.local_gas_station, 
    Icons.school, 
    Icons.shopping_bag, 
    Icons.directions_car, 
    Icons.medical_services,
    Icons.receipt_long, 
    Icons.confirmation_number, 
    Icons.home, 
    Icons.fastfood
  ];

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    final currentMonthTransactions = _filterTransactionsByMonth(transactionProvider.transactions);

    double totalBudget = budgetProvider.budgets.fold(0.0, (sum, item) => sum + item.limit);
    double totalUsed = 0.0;
    
    for (var budget in budgetProvider.budgets) {
      totalUsed += _calculateUsedAmount(currentMonthTransactions, budget.category);
    }
    
    double totalRemaining = totalBudget - totalUsed;
    double globalPercentage = totalBudget == 0 ? 0.0 : (totalUsed / totalBudget);

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [startBlue, endBlue]),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Anggaran Bulanan", style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()), style: GoogleFonts.nunito(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Sisa Anggaran", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                            Text("Terpakai", style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatCurrency(totalRemaining), style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.bold)),
                            Text("${(globalPercentage * 100).toStringAsFixed(0)}%", style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(value: globalPercentage.clamp(0.0, 1.0), backgroundColor: Colors.grey[200], color: Colors.amber, minHeight: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              // PERBAIKAN: Padding horizontal tetap 20, tapi vertical dikurangi
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Kelola Anggaran", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: () => _showBudgetDialog(context),
                        icon: const Icon(Icons.add, size: 18, color: Colors.white),
                        label: const Text("Tambah", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: startBlue, shape: const StadiumBorder()),
                      )
                    ],
                  ),
                  // PERBAIKAN: SizedBox diubah dari 15 ke 5 agar mepet
                  const SizedBox(height: 5), 
                  ListView.builder(
                    shrinkWrap: true,
                    // PERBAIKAN: Padding ListView di-zero agar tidak ada gap tambahan
                    padding: EdgeInsets.zero, 
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: budgetProvider.budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgetProvider.budgets[index];
                      double used = _calculateUsedAmount(currentMonthTransactions, budget.category);
                      return _buildBudgetCard(context, budget, used);
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget, double used) {
    double progress = (budget.limit == 0 ? 0.0 : (used / budget.limit)).toDouble().clamp(0.0, 1.0);
    
    return Container(
      // PERBAIKAN: Margin top di-set 0 dan bottom dikurangi agar antar kartu rapat
      margin: const EdgeInsets.only(top: 0, bottom: 10), 
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: startBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(IconData(budget.iconCode, fontFamily: 'MaterialIcons'), color: startBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.category, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("Limit: ${_formatCurrency(budget.limit)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              Text("${(progress * 100).toInt()}%", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress, 
              minHeight: 6, 
              backgroundColor: Colors.grey[100], 
              valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.red : startBlue)
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sisa: ${_formatCurrency(budget.limit - used)}", style: const TextStyle(fontSize: 10, color: Colors.black54)),
              Text("${_formatCurrency(used)} dipakai", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () => _showBudgetDialog(context, budget: budget),
              style: ElevatedButton.styleFrom(
                backgroundColor: startBlue, 
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              child: const Text("Kelola Anggaran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, {Budget? budget}) {
    final isEditing = budget != null;
    final nameController = TextEditingController(text: isEditing ? budget.category : '');
    final limitController = TextEditingController(text: isEditing ? NumberFormat.decimalPattern('id').format(budget.limit) : '');
    int selectedIconCode = isEditing ? budget.iconCode : _availableIcons[0].codePoint;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE9E9E9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? "Edit Anggaran" : "Tambah Anggaran Baru", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Nama Kategori", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: limitController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    decoration: InputDecoration(labelText: "Batas Anggaran", prefixText: "Rp ", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 15),
                  const Text("Pilih Ikon:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableIcons.map((icon) {
                      bool isSelected = selectedIconCode == icon.codePoint;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIconCode = icon.codePoint),
                        child: CircleAvatar(
                          backgroundColor: isSelected ? startBlue : Colors.white,
                          child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      if (isEditing)
                        IconButton(onPressed: () => _confirmDeleteBudget(context, budget.id), icon: const Icon(Icons.delete, color: Colors.red)),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: startBlue, padding: const EdgeInsets.symmetric(vertical: 15)),
                          onPressed: () {
                            final limit = double.tryParse(limitController.text.replaceAll('.', '')) ?? 0.0;
                            if (nameController.text.isNotEmpty && limit > 0) {
                              if (isEditing) {
                                Provider.of<BudgetProvider>(context, listen: false).updateBudget(budget.id, nameController.text, limit, selectedIconCode);
                              } else {
                                Provider.of<BudgetProvider>(context, listen: false).addBudget(Budget(
                                  id: DateTime.now().toString(), 
                                  category: nameController.text, 
                                  limit: limit,
                                  iconCode: selectedIconCode,
                                ));
                              }
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text("SIMPAN ANGGARAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  List<Transaction> _filterTransactionsByMonth(List<Transaction> allTx) {
    final now = DateTime.now();
    return allTx.where((tx) => tx.date.month == now.month && tx.date.year == now.year && tx.type == 'Expense').toList();
  }

  double _calculateUsedAmount(List<Transaction> transactions, String category) {
    return transactions
        .where((tx) => tx.category.toLowerCase().trim() == category.toLowerCase().trim())
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _confirmDeleteBudget(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(onPressed: () { 
            Provider.of<BudgetProvider>(context, listen: false).deleteBudget(id);
            Navigator.pop(ctx); Navigator.pop(context);
          }, child: const Text("HAPUS")),
        ],
      ),
    );
  }
}