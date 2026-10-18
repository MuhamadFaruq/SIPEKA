import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/core/constants/constants.dart';
import 'package:sipeka/core/utils/formatters.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/features/quick_action/domain/entities/quick_action_entity.dart';
import 'package:sipeka/features/quick_action/presentation/controllers/quick_action_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/transaction/presentation/screens/notification_tracker_screen.dart';
import 'package:sipeka/features/settings/presentation/screens/manage_icons_screen.dart';

class AutomationCustomizationSettingsScreen extends StatelessWidget {
  const AutomationCustomizationSettingsScreen({super.key});

  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  Widget _buildCard({required BuildContext context, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 10),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text(
          "Otomasi & Kustomisasi",
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
          _buildSectionTitle(context, "Kecerdasan Buatan (AI)"),
          _buildCard(
            context: context,
            child: _buildListTile(
              context: context,
              icon: Icons.notifications_active_rounded,
              title: "Pencatatan Otomatis (AI Bank Sync)",
              subtitle: "Deteksi dan catat transaksi otomatis dari SMS perbankan & notifikasi e-wallet",
              color: Colors.redAccent,
              onTap: () => Navigator.push(
                context,
                SmoothPageRoute(child: const NotificationTrackerScreen()),
              ),
            ),
          ),
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Kustomisasi Tampilan & Akses Cepat"),
          _buildCard(
            context: context,
            child: Column(
              children: [
                _buildListTile(
                  context: context,
                  icon: Icons.flash_on_rounded,
                  title: "Kelola Jalan Pintas",
                  subtitle: "Tambah atau atur transaksi cepat di layar beranda",
                  color: Colors.orange,
                  onTap: () => _showManageShortcutsDialog(context),
                ),
                const Divider(height: 1),
                _buildListTile(
                  context: context,
                  icon: Icons.emoji_symbols_rounded,
                  title: "Kelola Ikon Aplikasi",
                  subtitle: "Kustomisasi ikon kategori, dompet & transaksi",
                  color: Colors.deepPurple,
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(child: const ManageIconsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManageShortcutsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Theme.of(context).cardColor : const Color(0xFFE9E9E9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        final isDarkLocal = Theme.of(ctx).brightness == Brightness.dark;
        return Consumer<QuickActionProvider>(
          builder: (context, provider, child) {
            final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Kelola Jalan Pintas",
                    style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 15),
                  if (provider.actions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text("Belum ada jalan pintas", style: GoogleFonts.nunito(color: Colors.grey)),
                    )
                  else
                    ...provider.actions.map(
                      (action) => Card(
                        color: isDarkLocal ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: startBlue.withValues(alpha: 0.1),
                            child: Icon(action.icon, color: startBlue, size: 20),
                          ),
                          title: Text(action.label, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                          subtitle: Text("${currencyFormat.format(action.amount)} • ${action.category}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                onPressed: () => _showAddShortcutForm(context, existingAction: action),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDeleteShortcut(context, action.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: startBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _confirmDeleteShortcut(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Pintasan?", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text("Apakah Anda yakin ingin menghapus jalan pintas ini?", style: GoogleFonts.nunito(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: startBlue),
            onPressed: () {
              Provider.of<QuickActionProvider>(context, listen: false).removeAction(id);
              Navigator.pop(ctx);
              SipekaNotification.showWarning(context, "Pintasan dihapus");
            },
            child: Text("HAPUS", style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddShortcutForm(BuildContext context, {QuickAction? existingAction}) {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final nameController = TextEditingController(text: existingAction?.label);
    final amountController = TextEditingController(
      text: existingAction != null ? NumberFormat.decimalPattern('id').format(existingAction.amount) : "",
    );
    List<String> categories = budgetProvider.budgets.map((b) => b.category).toList();
    String? selectedCategory = existingAction?.category;
    if (selectedCategory != null && !categories.contains(selectedCategory)) {
      selectedCategory = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existingAction == null ? "Pintasan Baru" : "Edit Pintasan",
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: "Nama (Contoh: Parkir)",
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  value: selectedCategory,
                  hint: Text("Pilih Kategori", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  items: categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          ))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val),
                  decoration: const InputDecoration(border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: "Nominal (Rp)",
                    prefixText: "Rp ",
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: startBlue),
              onPressed: () {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty && selectedCategory != null) {
                  final provider = Provider.of<QuickActionProvider>(context, listen: false);
                  String cleanAmount = amountController.text.replaceAll('.', '');
                  double parsedAmount = double.tryParse(cleanAmount) ?? 0;
                  final budgetMatches = budgetProvider.budgets.where((b) => b.category == selectedCategory);
                  if (budgetMatches.isEmpty) {
                    SipekaNotification.showWarning(context, "Kategori anggaran tidak ditemukan!");
                    return;
                  }
                  final selectedBudget = budgetMatches.first;
                  final iconCode = selectedBudget.iconCode != 0
                      ? selectedBudget.iconCode
                      : AppIcons.getIcon(selectedCategory!).codePoint;
                  if (existingAction == null) {
                    provider.addAction(QuickAction(
                      id: const Uuid().v4(),
                      label: nameController.text,
                      icon: IconData(iconCode, fontFamily: 'MaterialIcons'),
                      category: selectedCategory!,
                      amount: parsedAmount,
                    ));
                  } else {
                    provider.updateAction(
                      existingAction.id,
                      nameController.text,
                      parsedAmount,
                      selectedCategory!,
                      IconData(iconCode, fontFamily: 'MaterialIcons'),
                    );
                  }
                  Navigator.pop(ctx);
                  SipekaNotification.showSuccess(context, "Pintasan berhasil disimpan!");
                } else {
                  SipekaNotification.showWarning(context, "Lengkapi semua data ya!");
                }
              },
              child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
