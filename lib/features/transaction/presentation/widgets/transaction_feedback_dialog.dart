import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sipeka/core/services/transaction_sentiment_service.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';

class TransactionFeedbackDialog extends StatefulWidget {
  final TransactionEntity transaction;

  const TransactionFeedbackDialog({
    super.key,
    required this.transaction,
  });

  /// Menampilkan popup feedback di tengah layar dengan transisi scale & fade halus
  static void show(BuildContext context, {required TransactionEntity transaction}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DismissFeedbackDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) => TransactionFeedbackDialog(transaction: transaction),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curvedValue.clamp(0.0, 1.0),
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

class _TransactionFeedbackDialogState extends State<TransactionFeedbackDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  bool _hasReacted = false;
  String? _selectedSentiment;
  Timer? _dismissTimer;

  static const int _countdownDurationSeconds = 4;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _countdownDurationSeconds),
    )..forward();

    // Auto-dismiss jika pengguna tidak menyentuh layar (zero friction)
    _dismissTimer = Timer(const Duration(seconds: _countdownDurationSeconds), () {
      if (mounted && !_hasReacted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onSelectSentiment(String sentimentKey, String label) async {
    if (_hasReacted) return;

    HapticFeedback.lightImpact();
    _dismissTimer?.cancel();
    _timerController.stop();

    setState(() {
      _hasReacted = true;
      _selectedSentiment = label;
    });

    await TransactionSentimentService.saveSentiment(widget.transaction.id, sentimentKey);

    // Beri jeda 600ms agar user melihat konfirmasi pilihan lalu tutup otomatis
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = widget.transaction.type == TransactionType.expense;
    final isTransfer = widget.transaction.category.toLowerCase().contains('transfer');

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final formattedAmount = currencyFormat.format(widget.transaction.amount);

    final Color badgeColor = isExpense
        ? (isTransfer ? const Color(0xFF5856D6) : const Color(0xFFFF9500))
        : const Color(0xFF10B981);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
              width: 1.2,
            ),
          ),
          child: _hasReacted
              ? _buildSuccessView(context)
              : _buildMainFeedbackView(
                  context: context,
                  isDark: isDark,
                  isExpense: isExpense,
                  isTransfer: isTransfer,
                  badgeColor: badgeColor,
                  formattedAmount: formattedAmount,
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 34,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "Pilihan Disimpan!",
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Refleksi '$_selectedSentiment' tercatat untuk evaluasi belanjamu.",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 12.5,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMainFeedbackView({
    required BuildContext context,
    required bool isDark,
    required bool isExpense,
    required bool isTransfer,
    required Color badgeColor,
    required String formattedAmount,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Header Row with Icon & Close Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpense
                        ? Icons.arrow_outward_rounded
                        : (isTransfer ? Icons.swap_horiz_rounded : Icons.south_west_rounded),
                    size: 15,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isExpense ? "Pengeluaran" : (isTransfer ? "Transfer" : "Pemasukan"),
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 20, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Transaksi Nominal & Info
        Text(
          formattedAmount,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "${widget.transaction.title} • ${widget.transaction.category}",
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // Pertanyaan Refleksi (Gojek-style Prompt)
        Text(
          isExpense
              ? "Bagaimana perasaanmu dengan transaksi ini?"
              : "Pundi-pundi tabunganmu bertambah! 🎉",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isExpense
              ? "Refleksi cepat untuk melatih kebiasaan belanja bijak"
              : "Alokasikan dengan bijak untuk masa depanmu",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 16),

        // 3 Tombol Emoji Reaksi (One-tap frictionless)
        if (isExpense)
          Row(
            children: [
              Expanded(
                child: _buildReactionCard(
                  emoji: "🎯",
                  title: "Bijak",
                  subtitle: "Puas & Perlu",
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => _onSelectSentiment("wise", "Bijak"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionCard(
                  emoji: "☕",
                  title: "Wajar",
                  subtitle: "Rutin biasa",
                  color: const Color(0xFF007AFF),
                  isDark: isDark,
                  onTap: () => _onSelectSentiment("normal", "Wajar"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionCard(
                  emoji: "🥲",
                  title: "Boros",
                  subtitle: "Impulsif",
                  color: const Color(0xFFFF3B30),
                  isDark: isDark,
                  onTap: () => _onSelectSentiment("impulsive", "Boros"),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildReactionCard(
                  emoji: "🤲",
                  title: "Berkah",
                  subtitle: "Syukur",
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => _onSelectSentiment("wise", "Berkah"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionCard(
                  emoji: "🏦",
                  title: "Ditabung",
                  subtitle: "Masa depan",
                  color: const Color(0xFF007AFF),
                  isDark: isDark,
                  onTap: () => _onSelectSentiment("normal", "Ditabung"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionCard(
                  emoji: "🎁",
                  title: "Reward",
                  subtitle: "Self-love",
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  onTap: () => _onSelectSentiment("normal", "Reward"),
                ),
              ),
            ],
          ),

        const SizedBox(height: 18),

        // Auto-dismiss indicator line (Zero Friction)
        AnimatedBuilder(
          animation: _timerController,
          builder: (context, child) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0 - _timerController.value,
                    minHeight: 2.5,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(badgeColor.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined, size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      "Menutup otomatis... (ketuk di mana saja untuk tutup)",
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReactionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 9.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
