import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';

class TransactionFeedbackDialog extends StatefulWidget {
  final TransactionEntity transaction;

  const TransactionFeedbackDialog({
    super.key,
    required this.transaction,
  });

  /// Menampilkan popup dialog ikonik SIPEKA: Maskot Si Peka + pesan manusiawi + gradient khas SIPEKA
  static void show(BuildContext context, {required TransactionEntity transaction}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DismissSipekaDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => TransactionFeedbackDialog(transaction: transaction),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curved.clamp(0.0, 1.0),
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TransactionFeedbackDialog> createState() => _TransactionFeedbackDialogState();
}

class _TransactionFeedbackDialogState extends State<TransactionFeedbackDialog> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss setelah 3.5 detik jika tidak disentuh (zero friction)
    _autoDismissTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _closeDialog() {
    _autoDismissTimer?.cancel();
    HapticFeedback.lightImpact();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = widget.transaction;
    final isExpense = tx.type == TransactionType.expense;
    final isTransfer = tx.category.toLowerCase().contains('transfer') ||
        tx.title.toLowerCase().contains('transfer');

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final formattedAmount = currency.format(tx.amount);

    // Salinan bahasa manusiawi, hangat, dan bersahabat ("Teman Keuangan Kamu")
    String title;
    String description;

    if (isTransfer) {
      title = "Beres, Transfer Sukses!";
      description = "Transfer senilai $formattedAmount sudah aman tercatat ke dompet tujuan kamu.";
    } else if (isExpense) {
      title = "Sip, Sudah Dicatat!";
      description = "Pengeluaran ${tx.category} senilai $formattedAmount sudah rapi tersimpan di dompet ${tx.wallet} kamu.";
    } else {
      title = "Asik, Cuan Masuk!";
      description = "Pemasukan senilai $formattedAmount sudah berhasil menambah saldo dompet ${tx.wallet} kamu.";
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2129) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Maskot Ikonik SIPEKA ("Si Peka - Teman Keuangan Kamu")
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                child: Container(
                  height: 168,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8F1FF), Color(0xFFD8E9FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/sipeka_success.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: const Color(0xFFEBF3FF),
                      child: const Center(
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 70,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Identitas SIPEKA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.18 : 0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "SIPEKA • Teman Keuangan",
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Judul Hangat & Manusiawi
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1B1D21),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Deskripsi Bersahabat
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF555962),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tombol Khas Gradient Biru SIPEKA
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _closeDialog,
                        child: Text(
                          "Oke, Siap!",
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
