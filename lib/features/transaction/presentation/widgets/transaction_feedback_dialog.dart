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

  /// Menampilkan pop-up feedback ringan di tengah layar dengan transisi lembut
  static void show(BuildContext context, {required TransactionEntity transaction}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DismissFeedbackDialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 260),
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
  bool _hasReacted = false;
  String? _selectedEmoji;
  String? _responseText;
  Timer? _dismissTimer;

  static const int _autoCloseSeconds = 4;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss senyap di background tanpa menampilkan timer robotik
    _dismissTimer = Timer(const Duration(seconds: _autoCloseSeconds), () {
      if (mounted && !_hasReacted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onSelectReaction({
    required String sentimentKey,
    required String emoji,
    required String friendlyResponse,
  }) async {
    if (_hasReacted) return;

    HapticFeedback.lightImpact();
    _dismissTimer?.cancel();

    setState(() {
      _hasReacted = true;
      _selectedEmoji = emoji;
      _responseText = friendlyResponse;
    });

    await TransactionSentimentService.saveSentiment(widget.transaction.id, sentimentKey);

    // Respons hangat muncul sekejap, lalu menutup otomatis
    await Future.delayed(const Duration(milliseconds: 700));
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

    final rawTitle = widget.transaction.title.trim();
    final rawCat = widget.transaction.category.trim();
    final displayTitle = (rawTitle.isNotEmpty && rawTitle.toLowerCase() != rawCat.toLowerCase())
        ? rawTitle
        : rawCat;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: _hasReacted
              ? _buildSuccessView(isDark)
              : _buildMainView(
                  context: context,
                  isDark: isDark,
                  isExpense: isExpense,
                  isTransfer: isTransfer,
                  displayTitle: displayTitle,
                  formattedAmount: formattedAmount,
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedEmoji ?? "✨",
            style: const TextStyle(fontSize: 38),
          ),
          const SizedBox(height: 10),
          Text(
            _responseText ?? "Tercatat!",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView({
    required BuildContext context,
    required bool isDark,
    required bool isExpense,
    required bool isTransfer,
    required String displayTitle,
    required String formattedAmount,
  }) {
    String questionText;
    if (isExpense) {
      questionText = "Gimana, worth it gak nih?";
    } else if (isTransfer) {
      questionText = "Transfer aman terkirim!";
    } else {
      questionText = "Alhamdulillah, rezeki masuk! ✨";
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Baris Atas: Info Ringkas Transaksi & Tombol Tutup
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$displayTitle • $formattedAmount",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Pertanyaan Singkat, Hangat & Manusiawi (Tanpa gaya AI/kuesioner kaku)
        Text(
          questionText,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),

        const SizedBox(height: 16),

        // 3 Tombol Reaksi Santai & Ramah
        if (isExpense)
          Row(
            children: [
              Expanded(
                child: _buildReactionBtn(
                  emoji: "😍",
                  label: "Worth it!",
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "wise",
                    emoji: "😍",
                    friendlyResponse: "Mantap, yang penting bermanfaat! ✨",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionBtn(
                  emoji: "👍",
                  label: "Pas kok",
                  color: const Color(0xFF007AFF),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "normal",
                    emoji: "👍",
                    friendlyResponse: "Sip, kebutuhan aman terkendali! 👌",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionBtn(
                  emoji: "😅",
                  label: "Khilaf",
                  color: const Color(0xFFFF5252),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "impulsive",
                    emoji: "😅",
                    friendlyResponse: "Santai, besok kita rem dikit ya! 😉",
                  ),
                ),
              ),
            ],
          )
        else if (isTransfer)
          Row(
            children: [
              Expanded(
                child: _buildReactionBtn(
                  emoji: "👍",
                  label: "Beres",
                  color: const Color(0xFF007AFF),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "normal",
                    emoji: "👍",
                    friendlyResponse: "Sip, transfer sukses dicatat! 👌",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionBtn(
                  emoji: "🤝",
                  label: "Selesai",
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "wise",
                    emoji: "🤝",
                    friendlyResponse: "Mantap, satu urusan selesai! 🤝",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionBtn(
                  emoji: "💼",
                  label: "Rutin",
                  color: const Color(0xFF5856D6),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "normal",
                    emoji: "💼",
                    friendlyResponse: "Keren, alur keuangan tertata rapi! ✨",
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildReactionBtn(
                  emoji: "🤲",
                  label: "Syukur",
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "wise",
                    emoji: "🤲",
                    friendlyResponse: "Semoga berkah dan makin lancar! 🤲",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionBtn(
                  emoji: "💰",
                  label: "Tabung",
                  color: const Color(0xFF007AFF),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "normal",
                    emoji: "💰",
                    friendlyResponse: "Keren, masa depan makin siap! 🚀",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReactionBtn(
                  emoji: "🎁",
                  label: "Reward",
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  onTap: () => _onSelectReaction(
                    sentimentKey: "normal",
                    emoji: "🎁",
                    friendlyResponse: "Kamu berhak nikmatin hasilnya! 🎉",
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReactionBtn({
    required String emoji,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
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
