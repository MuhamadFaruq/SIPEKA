import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/core/services/auth_service.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/features/settings/presentation/screens/sus_evaluation_screen.dart';

class HelpAboutSettingsScreen extends StatelessWidget {
  const HelpAboutSettingsScreen({super.key});

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
          "Bantuan & Informasi",
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
          _buildSectionTitle(context, "Panduan & Dukungan"),
          _buildCard(
            context: context,
            child: Column(
              children: [
                _buildListTile(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: "Pusat Bantuan & FAQ",
                  subtitle: "Panduan cara menggunakan fitur SIPEKA",
                  color: Colors.blue,
                  onTap: () => _showHelpCenterDialog(context),
                ),
                const Divider(height: 1),
                _buildListTile(
                  context: context,
                  icon: Icons.feedback_outlined,
                  title: "Kirim Masukan & Saran",
                  subtitle: "Bantu kami mengembangkan SIPEKA",
                  color: Colors.green,
                  onTap: () => _showFeedbackDialog(context),
                ),
                const Divider(height: 1),
                _buildListTile(
                  context: context,
                  icon: Icons.rate_review_outlined,
                  title: "Evaluasi Aplikasi (SUS)",
                  subtitle: "Kuesioner pengalaman pengguna SIPEKA",
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(child: const SUSEvaluationScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Tentang SIPEKA"),
          _buildCard(
            context: context,
            child: Column(
              children: [
                _buildListTile(
                  context: context,
                  icon: Icons.star_outline_rounded,
                  title: "Beri Rating",
                  subtitle: "Dukung pengembang di Google Play Store",
                  color: Colors.amber,
                  onTap: () => _showRatingToast(context),
                ),
                const Divider(height: 1),
                _buildListTile(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: "Tentang Aplikasi",
                  subtitle: "Informasi versi 1.0.0, lisensi & pengembang",
                  color: Colors.indigo,
                  onTap: () => _showAboutAppDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          Center(
            child: Column(
              children: [
                Text(
                  "SIPEKA",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Versi 1.0.0 • Offline-First Financial Suite",
                  style: GoogleFonts.nunito(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Pusat Bantuan & FAQ", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildFAQItem(
                context,
                "Apakah SIPEKA bisa digunakan secara offline?",
                "Ya! SIPEKA dirancang offline-first. Seluruh data transaksi, wishlist, dompet, dan tagihan disimpan secara lokal di memori HP Anda. Internet hanya digunakan saat Anda melakukan sinkronisasi awan atau menggunakan asisten AI.",
              ),
              const Divider(),
              _buildFAQItem(
                context,
                "Bagaimana cara kerja Dompet Bersama?",
                "Anda dapat mengaktifkan fitur Dompet Bersama pada salah satu dompet di menu 'Kelola Dompet & Rekening'. Aplikasi akan menghasilkan kode undangan unik 6 digit. Pasangan atau keluarga Anda cukup menekan tombol 'Gabung Dompet' dan memasukkan kode tersebut untuk sinkronisasi transaksi secara real-time.",
              ),
              const Divider(),
              _buildFAQItem(
                context,
                "Bagaimana cara mencatat transaksi dengan Suara?",
                "Ketuk tombol mikrofon biru di Dashboard utama, lalu katakan transaksi Anda dengan bahasa alami (contoh: 'Beli nasi goreng dua puluh ribu rupiah'). Asisten Gemini AI akan membaca ucapan Anda dan mengisi form pencatatan secara otomatis.",
              ),
              const Divider(),
              _buildFAQItem(
                context,
                "Apakah pemindaian foto struk (OCR) butuh kuota?",
                "Deteksi huruf dan teks dari foto struk belanja dilakukan secara lokal tanpa kuota data. Namun, jika ada internet dan API Gemini aktif, AI akan membantu menyaring nominal total secara cerdas dan otomatis. Jika offline, sistem akan menggunakan pencocokan pola lokal (Regex) sebagai cadangan gratis.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Tutup", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          question,
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
            child: Text(
              answer,
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Kirim Masukan & Saran", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masukan Anda sangat berharga bagi kami untuk membuat SIPEKA menjadi lebih baik.",
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Ketik saran atau keluhan Anda di sini...",
                hintStyle: GoogleFonts.nunito(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final text = feedbackController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await AuthService().sendFeedback(text);
                  if (context.mounted) {
                    SipekaNotification.showSuccess(context, "Terima kasih! Umpan balik Anda telah terkirim.");
                  }
                } catch (e) {
                  if (context.mounted) {
                    SipekaNotification.showWarning(context, "Gagal mengirim masukan. Silakan periksa koneksi internet Anda.");
                  }
                }
              } else {
                SipekaNotification.showWarning(context, "Mohon tuliskan masukan Anda terlebih dahulu.");
              }
            },
            child: Text("Kirim", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF00479E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "SIPEKA",
              style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "Sistem Pencatatan Keuangan",
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              "Versi 1.0.0 (Stabil)",
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF007AFF)),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              "SIPEKA adalah aplikasi pencatatan keuangan modern yang menggabungkan kemudahan pencatatan lokal terenkripsi, sinkronisasi cloud real-time (Dompet Bersama), serta kecerdasan buatan (Gemini AI) untuk voice recognition dan OCR scan struk.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Tutup", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRatingToast(BuildContext context) {
    SipekaNotification.showSuccess(context, "Terima kasih atas penilaian bintang 5 Anda!");
  }
}
