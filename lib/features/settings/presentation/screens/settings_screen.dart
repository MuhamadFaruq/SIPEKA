import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipeka/core/theme/theme_provider.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/features/settings/presentation/screens/financial_settings_screen.dart';
import 'package:sipeka/features/settings/presentation/screens/automation_customization_settings_screen.dart';
import 'package:sipeka/features/settings/presentation/screens/security_settings_screen.dart';
import 'package:sipeka/features/settings/presentation/screens/appearance_notification_settings_screen.dart';
import 'package:sipeka/features/settings/presentation/screens/data_cloud_settings_screen.dart';
import 'package:sipeka/features/settings/presentation/screens/help_about_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );

  Widget _buildCard({required BuildContext context, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSubMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailingBadge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 8),
                trailingBadge,
              ],
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(
          "Pengaturan",
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        children: [
          // Profil Pengguna Card
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              final googleUser = authSnapshot.data;
              return Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  final displayName = googleUser?.displayName ?? themeProvider.userName;
                  final emailOrStatus = googleUser?.email ?? "Pengguna Lokal SIPEKA";

                  return _buildCard(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: startBlue.withValues(alpha: 0.12),
                            backgroundImage: googleUser?.photoURL != null
                                ? NetworkImage(googleUser!.photoURL!)
                                : null,
                            child: googleUser?.photoURL == null
                                ? const Icon(Icons.person, color: Color(0xFF007AFF), size: 28)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emailOrStatus,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF007AFF)),
                            tooltip: "Ubah Nama Profil",
                            onPressed: () => _showEditProfileDialog(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 22),

          // KELOMPOK 1: KEUANGAN & OPERASIONAL
          _buildSectionTitle(context, "KEUANGAN & OPERASIONAL"),
          _buildCard(
            context: context,
            child: Column(
              children: [
                _buildSubMenuItem(
                  context: context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: "Keuangan & Dompet",
                  subtitle: "Dompet, sinkronisasi tabungan/hutang & tagihan rutin",
                  color: const Color(0xFF0D9488),
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(child: const FinancialSettingsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 70),
                _buildSubMenuItem(
                  context: context,
                  icon: Icons.auto_awesome_rounded,
                  title: "Otomasi & Kustomisasi",
                  subtitle: "AI Bank Sync, jalan pintas & kustomisasi ikon kategori",
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(child: const AutomationCustomizationSettingsScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // KELOMPOK 2: PREFERENSI & SISTEM
          _buildSectionTitle(context, "PREFERENSI & SISTEM"),
          _buildCard(
            context: context,
            child: Column(
              children: [
                _buildSubMenuItem(
                  context: context,
                  icon: Icons.security_rounded,
                  title: "Keamanan & Privasi",
                  subtitle: "Kunci PIN, biometrik, blur layar & kunci otomatis",
                  color: const Color(0xFF6366F1),
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(child: const SecuritySettingsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 70),
                _buildSubMenuItem(
                  context: context,
                  icon: Icons.palette_outlined,
                  title: "Tampilan & Pengingat",
                  subtitle: "Mode gelap dan jadwal notifikasi pengingat harian",
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(child: const AppearanceNotificationSettingsScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // KELOMPOK 3: DATA & PENYIMPANAN
          _buildSectionTitle(context, "DATA & CADANGAN"),
          _buildCard(
            context: context,
            child: _buildSubMenuItem(
              context: context,
              icon: Icons.cloud_sync_rounded,
              title: "Data & Cadangan Cloud",
              subtitle: "Akun Google, cadangkan/pulihkan, ekspor CSV & reset data",
              color: const Color(0xFF007AFF),
              onTap: () => Navigator.push(
                context,
                SmoothPageRoute(child: const DataCloudSettingsScreen()),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // KELOMPOK 4: DUKUNGAN
          _buildSectionTitle(context, "INFORMASI LAINNYA"),
          _buildCard(
            context: context,
            child: _buildSubMenuItem(
              context: context,
              icon: Icons.help_center_outlined,
              title: "Bantuan & Informasi",
              subtitle: "Pusat bantuan FAQ, masukan, evaluasi SUS & tentang SIPEKA",
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                SmoothPageRoute(child: const HelpAboutSettingsScreen()),
              ),
            ),
          ),

          const SizedBox(height: 35),

          // FOOTER
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: startBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_rounded, size: 14, color: startBlue),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "SIPEKA v1.0.0 (Stabil)",
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Offline-First Financial Suite • Gemini AI Enabled",
                  style: GoogleFonts.nunito(
                    color: Colors.grey.withValues(alpha: 0.7),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final nameController = TextEditingController(text: themeProvider.userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit Nama Profil",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: "Nama Anda",
            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("BATAL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: startBlue),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                themeProvider.updateName(nameController.text.trim());
                Navigator.pop(ctx);
                SipekaNotification.showSuccess(context, "Nama profil diperbarui!");
              }
            },
            child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
