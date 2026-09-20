import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:sipeka/core/constants/constants.dart';
import 'package:sipeka/core/widgets/icon_picker_sheet.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/wallet/domain/entities/wallet_entity.dart';
import 'package:sipeka/features/quick_action/presentation/controllers/quick_action_provider.dart';

class ManageIconsScreen extends StatefulWidget {
  const ManageIconsScreen({super.key});

  @override
  State<ManageIconsScreen> createState() => _ManageIconsScreenState();
}

class _ManageIconsScreenState extends State<ManageIconsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color _accentColor = const Color(0xFF007AFF);
  final Color _accentDark = const Color(0xFF00479E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Kelola Ikon",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentColor, _accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
          tabs: const [
            Tab(text: "Kategori"),
            Tab(text: "Dompet"),
            Tab(text: "Pintasan"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBudgetTab(context, isDark),
          _buildWalletTab(context, isDark),
          _buildQuickActionTab(context, isDark),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // TAB 1: Kategori Anggaran
  // ──────────────────────────────────────────────────
  Widget _buildBudgetTab(BuildContext context, bool isDark) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, _) {
        final budgets = budgetProvider.budgets;

        if (budgets.isEmpty) {
          return _buildEmptyState(
            icon: Icons.pie_chart_outline_rounded,
            message: "Belum ada kategori anggaran",
            subtitle: "Tambahkan anggaran terlebih dahulu di halaman Budget",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            final iconData = IconData(budget.iconCode, fontFamily: 'MaterialIcons');
            final iconName = AppIcons.getIconName(budget.iconCode);

            return _buildIconListTile(
              context: context,
              isDark: isDark,
              iconData: iconData,
              iconColor: _accentColor,
              title: budget.category,
              subtitle: "Ikon: $iconName  •  Limit: ${_formatCurrency(budget.limit)}",
              onTap: () async {
                final selected = await IconPickerSheet.show(
                  context,
                  currentIconCode: budget.iconCode,
                );
                if (selected != null && context.mounted) {
                  await budgetProvider.updateBudget(
                    budget.id,
                    budget.category,
                    budget.limit,
                    selected.codePoint,
                  );
                  if (context.mounted) {
                    SipekaNotification.showSuccess(
                      context,
                      "Ikon \"${budget.category}\" berhasil diubah!",
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────
  // TAB 2: Dompet & Rekening
  // ──────────────────────────────────────────────────
  Widget _buildWalletTab(BuildContext context, bool isDark) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        final wallets = walletProvider.wallets;

        if (wallets.isEmpty) {
          return _buildEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            message: "Belum ada dompet",
            subtitle: "Tambahkan dompet terlebih dahulu di Kelola Dompet",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: wallets.length,
          itemBuilder: (context, index) {
            final wallet = wallets[index];
            final iconData = IconData(wallet.iconCode, fontFamily: 'MaterialIcons');
            final walletColor = Color(int.parse(wallet.colorHex.replaceFirst('#', '0xFF')));
            final iconName = AppIcons.getIconName(wallet.iconCode);

            return _buildIconListTile(
              context: context,
              isDark: isDark,
              iconData: iconData,
              iconColor: walletColor,
              title: wallet.name,
              subtitle: "Ikon: $iconName",
              onTap: () async {
                final selected = await IconPickerSheet.show(
                  context,
                  currentIconCode: wallet.iconCode,
                );
                if (selected != null && context.mounted) {
                  final updatedWallet = WalletEntity(
                    id: wallet.id,
                    name: wallet.name,
                    initialBalance: wallet.initialBalance,
                    iconCode: selected.codePoint,
                    colorHex: wallet.colorHex,
                    inviteCode: wallet.inviteCode,
                    ownerId: wallet.ownerId,
                    isShared: wallet.isShared,
                  );
                  await walletProvider.updateWallet(updatedWallet);
                  if (context.mounted) {
                    SipekaNotification.showSuccess(
                      context,
                      "Ikon \"${wallet.name}\" berhasil diubah!",
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────
  // TAB 3: Jalan Pintas / Quick Action
  // ──────────────────────────────────────────────────
  Widget _buildQuickActionTab(BuildContext context, bool isDark) {
    return Consumer<QuickActionProvider>(
      builder: (context, quickActionProvider, _) {
        final actions = quickActionProvider.actions;

        if (actions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.flash_on_outlined,
            message: "Belum ada jalan pintas",
            subtitle: "Tambahkan jalan pintas di halaman Home atau Settings",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final iconName = AppIcons.getIconName(action.icon.codePoint);

            return _buildIconListTile(
              context: context,
              isDark: isDark,
              iconData: action.icon,
              iconColor: Colors.orange,
              title: action.label,
              subtitle: "Ikon: $iconName  •  ${_formatCurrency(action.amount)}",
              onTap: () async {
                final selected = await IconPickerSheet.show(
                  context,
                  currentIconCode: action.icon.codePoint,
                );
                if (selected != null && context.mounted) {
                  await quickActionProvider.updateIconOnly(action.id, selected);
                  if (context.mounted) {
                    SipekaNotification.showSuccess(
                      context,
                      "Ikon \"${action.label}\" berhasil diubah!",
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────
  // Shared UI Components
  // ──────────────────────────────────────────────────

  Widget _buildIconListTile({
    required BuildContext context,
    required bool isDark,
    required IconData iconData,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon preview
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: _accentColor),
                      const SizedBox(width: 4),
                      Text(
                        "Ubah",
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }
}
