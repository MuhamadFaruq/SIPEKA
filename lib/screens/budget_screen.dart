// lib/screens/budget_screen.dart

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
import '../utils/constants.dart'; 
import '../utils/notifications.dart';

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
    // Cek apakah Dark Mode sedang aktif
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final currentMonthTransactions = _filterTransactionsByMonth(transactionProvider.transactions);

    double totalBudget = budgetProvider.budgets.fold(0.0, (sum, item) => sum + item.limit);
    double totalUsed = 0.0;
    
    for (var budget in budgetProvider.budgets) {
      totalUsed += _calculateUsedAmount(currentMonthTransactions, budget.category);
    }
    
    double totalRemaining = totalBudget - totalUsed;
    double globalPercentage = totalBudget == 0 ? 0.0 : (totalUsed / totalBudget);

    return Scaffold(
      // --- FIX: Background dinamis ---
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    // --- FIX: Warna Card di Header dinamis ---
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Sisa Anggaran", style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color
                            )),
                            Text("Terpakai", style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatCurrency(totalRemaining), style: GoogleFonts.nunito(
                              fontSize: 28, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color
                            )),
                            Text("${(globalPercentage * 100).toStringAsFixed(0)}%", style: GoogleFonts.nunito(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color
                            )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: globalPercentage.clamp(0.0, 1.0), 
                            backgroundColor: isDark ? Colors.white10 : Colors.grey[200], 
                            color: Colors.amber, 
                            minHeight: 8
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Kelola Anggaran", style: GoogleFonts.nunito(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color
                      )),
                      ElevatedButton.icon(
                        onPressed: () => _showBudgetDialog(context),
                        icon: const Icon(Icons.add, size: 18, color: Colors.white),
                        label: const Text("Tambah", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: startBlue, shape: const StadiumBorder()),
                      )
                    ],
                  ),
                  const SizedBox(height: 5), 
                  ListView.builder(
                    shrinkWrap: true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double progress = (budget.limit == 0 ? 0.0 : (used / budget.limit)).toDouble().clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 10), 
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // FIX: Dinamis
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02), 
            blurRadius: 8
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: startBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(AppIcons.getIcon(budget.category), color: startBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.category, style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color
                    )),
                    Text("Limit: ${_formatCurrency(budget.limit)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              Text("${(progress * 100).toInt()}%", style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color
              )),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress, 
              minHeight: 6, 
              backgroundColor: isDark ? Colors.white10 : Colors.grey[100], 
              valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.red : startBlue)
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sisa: ${_formatCurrency(budget.limit - used)}", style: TextStyle(
                fontSize: 10, 
                color: isDark ? Colors.white70 : Colors.black54
              )),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mainContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // FIX: Dinamis
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            void saveProcess() {
              final name = nameController.text.trim();
              final limitStr = limitController.text.replaceAll('.', '');
              final limit = double.tryParse(limitStr) ?? 0;

              if (name.isEmpty || limit <= 0) {
                SipekaNotification.showWarning(context, "Nama dan nominal harus diisi!");
                return;
              }

              final budgetProvider = Provider.of<BudgetProvider>(mainContext, listen: false);

              if (isEditing) {
                budgetProvider.updateBudget(budget.id, name, limit, selectedIconCode);
              } else {
                budgetProvider.addBudget(
                  Budget(
                    id: DateTime.now().toString(),
                    category: name,
                    limit: limit,
                    iconCode: selectedIconCode,
                  ),
                );
              }
              
              Navigator.pop(ctx); 
              
              Future.delayed(Duration.zero, () {
                if (mainContext.mounted) {
                  SipekaNotification.showSuccess(
                    mainContext, 
                    isEditing ? "Anggaran diperbarui!" : "Anggaran baru ditambahkan!"
                  );
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? "Edit Anggaran" : "Tambah Anggaran Baru", style: GoogleFonts.nunito(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                  )),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: "Nama Kategori", 
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true, 
                      fillColor: Theme.of(context).cardColor, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: limitController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: "Batas Anggaran", 
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixText: "Rp ", 
                      prefixStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      filled: true, 
                      fillColor: Theme.of(context).cardColor, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text("Pilih Ikon:", style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                  )),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableIcons.map((icon) {
                      bool isSelected = selectedIconCode == icon.codePoint;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIconCode = icon.codePoint),
                        child: CircleAvatar(
                          backgroundColor: isSelected ? startBlue : Theme.of(context).cardColor,
                          child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      if (isEditing)
                        IconButton(onPressed: () => _confirmDeleteBudget(mainContext, budget.id), icon: const Icon(Icons.delete, color: Colors.red)),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: startBlue, padding: const EdgeInsets.symmetric(vertical: 15)),
                          onPressed: saveProcess,
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

  void _confirmDeleteBudget(BuildContext context, String id) {
    final budgetContext = context;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus?", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text("Apakah Anda yakin ingin menghapus anggaran ini?", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { 
              Provider.of<BudgetProvider>(budgetContext, listen: false).deleteBudget(id);
              Navigator.pop(ctx); 
              Navigator.pop(context); 
              Future.delayed(Duration.zero, () {
                if (budgetContext.mounted) {
                  SipekaNotification.showWarning(budgetContext, "Anggaran berhasil dihapus");
                }
              });
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Fungsi Utility ---
  List<Transaction> _filterTransactionsByMonth(List<Transaction> allTx) {
    final now = DateTime.now();
    return allTx.where((tx) => tx.date.month == now.month && tx.date.year == now.year && (tx.type == 'Expense' || tx.type == 'Pengeluaran')).toList();
  }

  double _calculateUsedAmount(List<Transaction> transactions, String category) {
    return transactions
        .where((tx) => tx.category.toLowerCase().trim() == category.toLowerCase().trim())
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }
}