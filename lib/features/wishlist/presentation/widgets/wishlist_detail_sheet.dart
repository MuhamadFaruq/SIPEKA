import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/wishlist_entity.dart';
import '../../domain/entities/wishlist_history_entity.dart';
import '../controllers/wishlist_provider.dart';

class WishlistDetailSheet extends StatefulWidget {
  final WishlistItem item;
  final Function(WishlistItem) onNabungTap;
  final Function(WishlistItem) onTarikTap;

  const WishlistDetailSheet({
    super.key,
    required this.item,
    required this.onNabungTap,
    required this.onTarikTap,
  });

  @override
  State<WishlistDetailSheet> createState() => _WishlistDetailSheetState();
}

class _WishlistDetailSheetState extends State<WishlistDetailSheet> {
  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  late Future<List<WishlistHistoryEntity>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final provider = Provider.of<WishlistProvider>(context, listen: false);
    _historyFuture = provider.getHistoryForWishlist(widget.item.id);
  }

  String _formatRupiah(double number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<WishlistProvider>(context);

    // Dapatkan data item terbaru dari provider jika ada perubahan saldo
    final currentItem = provider.items.firstWhere(
      (it) => it.id == widget.item.id,
      orElse: () => widget.item,
    );

    final double progress = currentItem.progress;
    final double remaining = (currentItem.targetAmount - currentItem.savedAmount).clamp(0.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header detail impian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [startBlue.withOpacity(0.15), endBlue.withOpacity(0.15)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_awesome, color: startBlue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentItem.title,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Target: ${_formatRupiah(currentItem.targetAmount)}",
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Terkumpul",
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: currentItem.isCompleted
                                    ? Colors.green.withOpacity(0.15)
                                    : startBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${(progress * 100).toInt()}%",
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: currentItem.isCompleted ? Colors.green : startBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRupiah(currentItem.savedAmount),
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              currentItem.isCompleted ? Colors.green : startBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentItem.isCompleted
                                  ? "🎉 Target tercapai penuh!"
                                  : "Kurang ${_formatRupiah(remaining)} lagi",
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: currentItem.isCompleted ? Colors.green : Colors.grey[600],
                              ),
                            ),
                            Text(
                              "Target: ${_formatRupiah(currentItem.targetAmount)}",
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [startBlue, endBlue]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: currentItem.isCompleted
                                ? null
                                : () async {
                                    await widget.onNabungTap(currentItem);
                                    if (mounted) setState(() => _loadHistory());
                                  },
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                            label: Text(
                              "Nabung",
                              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      if (currentItem.savedAmount > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.orange, Color(0xFFE65100)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await widget.onTarikTap(currentItem);
                                if (mounted) setState(() => _loadHistory());
                              },
                              icon: const Icon(Icons.savings_outlined, color: Colors.white, size: 18),
                              label: Text(
                                "Tarik Saldo",
                                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section Title: Riwayat Tabungan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Riwayat Tabungan",
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Icon(Icons.history_rounded, size: 20, color: Colors.grey[500]),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // History list
                  FutureBuilder<List<WishlistHistoryEntity>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final historyList = snapshot.data ?? [];

                      if (historyList.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                "Belum Ada Riwayat Mutasi",
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Setiap kamu menabung atau menarik uang, mutasinya akan tercatat rapi di sini.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: historyList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final h = historyList[index];
                          final isDeposit = h.isDeposit;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Icon badge
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isDeposit
                                        ? Colors.green.withOpacity(0.12)
                                        : Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isDeposit ? Colors.green : Colors.orange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Label & DateTime & Notes
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isDeposit ? "Nabung Masuk" : "Penarikan Tabungan",
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDateTime(h.date),
                                        style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      if (h.notes != null && h.notes!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.notes_rounded, size: 12, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                h.notes!,
                                                style: GoogleFonts.nunito(
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Amount
                                Text(
                                  "${isDeposit ? '+' : '-'}${_formatRupiah(h.amount)}",
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDeposit ? Colors.green : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
