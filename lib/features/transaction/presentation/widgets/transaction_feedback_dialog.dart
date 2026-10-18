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

  /// Menampilkan popup konfirmasi transaksi ala Gojek dengan animasi logo SIPEKA
  static void show(BuildContext context, {required TransactionEntity transaction}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DismissFeedbackDialog',
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
    HapticFeedback.lightImpact();

    // Auto-dismiss dalam 4 detik jika pengguna tidak menekan tombol (zero friction)
    _autoDismissTimer = Timer(const Duration(milliseconds: 4000), () {
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

  String _getTitle() {
    final tx = widget.transaction;
    final isTransfer = tx.category.toLowerCase().contains('transfer') ||
        tx.title.toLowerCase().contains('transfer');

    if (isTransfer) {
      return "Transfer Berhasil!";
    } else if (tx.type == TransactionType.income) {
      return "Hore, Cuan Masuk!";
    } else {
      return "Sip, Transaksi Tercatat!";
    }
  }

  String _getSubtitle() {
    final tx = widget.transaction;
    final isTransfer = tx.category.toLowerCase().contains('transfer') ||
        tx.title.toLowerCase().contains('transfer');
    final formattedAmount = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(tx.amount);

    if (isTransfer) {
      return "Pemindahan dana sebesar $formattedAmount ke ${tx.wallet} telah selesai diproses.";
    } else if (tx.type == TransactionType.income) {
      return "Pemasukan sebesar $formattedAmount dari ${tx.category} sudah ditambahkan ke saldo ${tx.wallet}.";
    } else {
      return "Pengeluaran sebesar $formattedAmount untuk ${tx.category} sudah rapi tersimpan di ${tx.wallet}.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Banner Animasi Logo SIPEKA (Sesuai gaya ilustrasi Gojek)
              Stack(
                children: [
                  Container(
                    height: 165,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: Image.asset(
                        'assets/images/sipeka_logo_anim.gif',
                        height: 145,
                        width: 145,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Judul Singkat, Padat & Manusiawi (2-3 kata)
              Text(
                _getTitle(),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),

              // 3. Deskripsi Ramah & Jelas
              Text(
                _getSubtitle(),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),

              // 4. Tombol "Oke" ala Gojek
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Text(
                    "Oke",
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
      ),
    );
  }
}
