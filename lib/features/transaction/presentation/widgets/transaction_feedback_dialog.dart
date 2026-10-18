import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';

class TransactionFeedbackDialog extends StatefulWidget {
  final TransactionEntity transaction;

  const TransactionFeedbackDialog({
    super.key,
    required this.transaction,
  });

  /// Menampilkan HUD animasi sukses yang singkat, padat, dan manusiawi di tengah layar
  static void show(BuildContext context, {required TransactionEntity transaction}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DismissFeedbackDialog',
      barrierColor: Colors.black.withValues(alpha: 0.35),
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

class _TransactionFeedbackDialogState extends State<TransactionFeedbackDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _textAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 1. Lingkaran membal membesar
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );

    // 2. Garis centang terlukis
    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.85, curve: Curves.easeInOutCubic),
    );

    // 3. Teks manusiawi muncul lembut
    _textAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Haptic feedback halus saat tanda centang terlukis
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) HapticFeedback.mediumImpact();
    });

    // Auto-dismiss cepat (1.5 detik), singkat, padat, tanpa membebani user
    _dismissTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _getHumanFriendlyTitle() {
    final tx = widget.transaction;
    final isTransfer = tx.category.toLowerCase().contains('transfer') ||
        tx.title.toLowerCase().contains('transfer');

    if (isTransfer) {
      return "Beres, transfer selesai!";
    } else if (tx.type == TransactionType.income) {
      return "Asik, cuan masuk!";
    } else {
      return "Sip, tercatat!";
    }
  }

  Color _getAccentColor() {
    final tx = widget.transaction;
    final isTransfer = tx.category.toLowerCase().contains('transfer') ||
        tx.title.toLowerCase().contains('transfer');

    if (isTransfer) {
      return const Color(0xFF007AFF); // Apple Blue
    } else if (tx.type == TransactionType.income) {
      return const Color(0xFF10B981); // Emerald Green
    } else {
      return const Color(0xFF10B981); // Crisp Success Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getAccentColor();
    final humanTitle = _getHumanFriendlyTitle();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1E24) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1.2,
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lingkaran Centang Beranimasi
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.38),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _AnimatedCheckmarkPainter(
                            progress: _checkAnimation.value,
                            color: Colors.white,
                            strokeWidth: 3.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Teks Pendekatan Manusiawi (2-3 Kata)
                    Transform.scale(
                      scale: _textAnimation.value,
                      child: Opacity(
                        opacity: _textAnimation.value.clamp(0.0, 1.0),
                        child: Text(
                          humanTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1A1D20),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter untuk menggambar goresan tanda centang secara dinamis dan mulus
class _AnimatedCheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _AnimatedCheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Titik awal, sudut bawah, dan ujung atas tanda centang
    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.72, size.height * 0.36);

    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;
    final currentLength = totalLength * progress.clamp(0.0, 1.0);

    final extractPath = metric.extractPath(0.0, currentLength);
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_AnimatedCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
