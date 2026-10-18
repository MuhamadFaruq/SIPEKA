import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/services/finance_sync_service.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/wallet/presentation/screens/manage_wallets_screen.dart';
import 'package:sipeka/features/bill/presentation/screens/manage_bills_screen.dart';

class FinancialSettingsScreen extends StatelessWidget {
  const FinancialSettingsScreen({super.key});

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

  Widget _buildFinanceSyncTile(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        FinanceSyncService.instance.getSyncMode(),
        FinanceSyncService.instance.getDefaultWallet(context),
      ]),
      builder: (context, snapshot) {
        final mode = (snapshot.data?[0] as FinanceSyncMode?) ?? FinanceSyncMode.manual;
        final defaultWallet = (snapshot.data?[1] as String?) ?? 'Dompet';

        String subtitleText;
        if (mode == FinanceSyncMode.automatic) {
          subtitleText = "Otomatis (Dompet: $defaultWallet)";
        } else if (mode == FinanceSyncMode.manual) {
          subtitleText = "Manual (Pilih lokasi saldo tiap transaksi)";
        } else {
          subtitleText = "Nonaktif (Hanya catatan mandiri)";
        }

        return _buildListTile(
          context: context,
          icon: Icons.sync_alt_rounded,
          title: "Sinkronisasi Tabungan & Hutang",
          subtitle: subtitleText,
          color: Colors.green,
          onTap: () => _showFinanceSyncDialog(context),
        );
      },
    );
  }

  void _showFinanceSyncDialog(BuildContext context) async {
    final currentMode = await FinanceSyncService.instance.getSyncMode();
    final currentDefaultWallet = await FinanceSyncService.instance.getDefaultWallet(context);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final wallets = walletProvider.wallets;

    FinanceSyncMode selectedMode = currentMode;
    String selectedWallet = currentDefaultWallet;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sync_alt_rounded, color: Colors.green, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sinkronisasi Tabungan & Hutang",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              "Atur pemotongan & penambahan saldo dompet",
                              style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "PILIH MODE SINKRONISASI",
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildSyncModeOption(
                    context: context,
                    mode: FinanceSyncMode.manual,
                    currentSelected: selectedMode,
                    title: "Manual (Rekomendasi)",
                    subtitle: "Tampilkan pilihan lokasi saldo (dompet) setiap menabung, tarik tabungan, atau pelunasan hutang.",
                    icon: Icons.touch_app_outlined,
                    onTap: () => setModalState(() => selectedMode = FinanceSyncMode.manual),
                  ),
                  const SizedBox(height: 8),

                  _buildSyncModeOption(
                    context: context,
                    mode: FinanceSyncMode.automatic,
                    currentSelected: selectedMode,
                    title: "Otomatis",
                    subtitle: "Langsung potong/tambah saldo ke dompet default tanpa konfirmasi tambahan.",
                    icon: Icons.bolt_rounded,
                    onTap: () => setModalState(() => selectedMode = FinanceSyncMode.automatic),
                  ),
                  const SizedBox(height: 8),

                  _buildSyncModeOption(
                    context: context,
                    mode: FinanceSyncMode.disabled,
                    currentSelected: selectedMode,
                    title: "Nonaktif",
                    subtitle: "Hanya sebagai buku catatan mandiri (saldo dompet tidak terpengaruh).",
                    icon: Icons.block_flipped,
                    onTap: () => setModalState(() => selectedMode = FinanceSyncMode.disabled),
                  ),

                  if (selectedMode == FinanceSyncMode.automatic) ...[
                    const SizedBox(height: 16),
                    Text(
                      "DOMPET DEFAULT (LOKASI SALDO)",
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: wallets.any((w) => w.name == selectedWallet)
                              ? selectedWallet
                              : (wallets.isNotEmpty ? wallets.first.name : 'Dompet'),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.green),
                          items: (wallets.isNotEmpty ? wallets.map((w) => w.name).toList() : ['Dompet'])
                              .map((name) => DropdownMenuItem(
                                    value: name,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        Text(name, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedWallet = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await FinanceSyncService.instance.setSyncMode(selectedMode);
                        if (selectedMode == FinanceSyncMode.automatic) {
                          await FinanceSyncService.instance.setDefaultWallet(selectedWallet);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          SipekaNotification.showSuccess(
                            context,
                            "Pengaturan sinkronisasi disimpan (${selectedMode.label})",
                          );
                        }
                      },
                      child: Text(
                        "SIMPAN PENGATURAN",
                        style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildSyncModeOption({
    required BuildContext context,
    required FinanceSyncMode mode,
    required FinanceSyncMode currentSelected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentSelected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF).withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF007AFF) : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isSelected ? const Color(0xFF007AFF) : Colors.grey).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? const Color(0xFF007AFF) : Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF007AFF) : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF007AFF) : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text("Pengaturan Keuangan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [startBlue, endBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 10),
            child: Text(
              "Dompet & Aliran Kas",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          _buildCard(
            context: context,
            child: Column(
              children: [
                _buildListTile(
                  context: context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: "Kelola Dompet & Rekening",
                  subtitle: "Tambah, edit rekening, atau dompet bersama",
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(child: const ManageWalletsScreen()),
                  ),
                ),
                const Divider(height: 1),
                _buildFinanceSyncTile(context),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 10),
            child: Text(
              "Kewajiban Rutin",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          _buildCard(
            context: context,
            child: _buildListTile(
              context: context,
              icon: Icons.repeat_on_rounded,
              title: "Tagihan & Transaksi Berulang",
              subtitle: "Atur tagihan bulanan dan cicilan rutin",
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                SmoothPageRoute(child: const ManageBillsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
