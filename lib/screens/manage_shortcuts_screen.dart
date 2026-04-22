import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/quick_action_provider.dart';
import '../providers/budget_provider.dart';
import '../models/quick_action_model.dart';
import '../utils/formatters.dart';
import '../utils/notifications.dart';
import 'package:intl/intl.dart';

class ManageShortcutsScreen extends StatelessWidget {
  const ManageShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quickActionProvider = Provider.of<QuickActionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // --- FIX: Background dinamis ---
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Kelola Jalan Pintas", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF00479E)]),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: quickActionProvider.actions.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: quickActionProvider.actions.length,
              itemBuilder: (context, index) {
                final action = quickActionProvider.actions[index];
                return _buildShortcutTile(context, action);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showShortcutDialog(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Belum ada jalan pintas", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildShortcutTile(BuildContext context, QuickAction action) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        // --- FIX: Warna kartu dinamis ---
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05), 
            blurRadius: 10
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
          child: Icon(action.icon, color: const Color(0xFF007AFF)),
        ),
        title: Text(
          action.label, 
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color // FIX: Warna teks
          )
        ),
        subtitle: Text(
          currencyFormat.format(action.amount), 
          style: GoogleFonts.nunito(color: Colors.grey[600])
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.orange),
              onPressed: () => _showShortcutDialog(context, action: action),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, action),
            ),
          ],
        ),
      ),
    );
  }

  void _showShortcutDialog(BuildContext context, {QuickAction? action}) {
    final isEdit = action != null;
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final quickActionProvider = Provider.of<QuickActionProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final labelController = TextEditingController(text: isEdit ? action.label : '');
    final amountController = TextEditingController(
      text: isEdit ? NumberFormat.decimalPattern('id').format(action.amount) : ''
    );
    String? selectedKategori = isEdit ? action.category : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // --- FIX: Background bottomsheet dinamis ---
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 25, left: 20, right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? "Ubah Jalan Pintas" : "Tambah Jalan Pintas", 
                  style: GoogleFonts.nunito(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                  )
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: labelController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: "Nama Pintasan (Misal: Makan Siang)",
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true, 
                    fillColor: Theme.of(context).cardColor, // FIX: Warna input
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // FIX: Warna dropdown box
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: Theme.of(context).cardColor, // FIX: Menu dropdown
                      hint: Text("Pilih Kategori Anggaran", style: GoogleFonts.nunito(color: Colors.grey)),
                      value: selectedKategori,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      items: budgetProvider.budgets.map((b) => b.category).map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedKategori = val),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: "Nominal Cepat",
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
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF00479E)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () {
                        double amt = double.tryParse(amountController.text.replaceAll('.', '')) ?? 0;
                        if (labelController.text.isNotEmpty && selectedKategori != null && amt > 0) {
                          final selectedBudget = budgetProvider.budgets.firstWhere((b) => b.category == selectedKategori);
                          
                          if (isEdit) {
                            quickActionProvider.updateAction(
                              action.id,
                              labelController.text,
                              amt,
                              selectedKategori!,
                              IconData(selectedBudget.iconCode, fontFamily: 'MaterialIcons'),
                            );
                          } else {
                            quickActionProvider.addAction(QuickAction(
                              id: DateTime.now().toString(),
                              label: labelController.text,
                              category: selectedKategori!,
                              amount: amt,
                              icon: IconData(selectedBudget.iconCode, fontFamily: 'MaterialIcons'),
                            ));
                          }
                          Navigator.pop(ctx);
                          SipekaNotification.showSuccess(context, isEdit ? "Pintasan diperbarui!" : "Pintasan dibuat!");
                        }
                      },
                      child: Text("SIMPAN", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _confirmDelete(BuildContext context, QuickAction action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Pintasan?", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text("Yakin ingin menghapus '${action.label}'?", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<QuickActionProvider>(context, listen: false).removeAction(action.id);
              Navigator.pop(ctx);
              SipekaNotification.showWarning(context, "Pintasan dihapus");
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}