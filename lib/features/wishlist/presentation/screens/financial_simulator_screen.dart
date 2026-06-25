import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:sipeka/core/database/database_helper.dart';
import 'package:sipeka/core/services/ai_service.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:sipeka/core/utils/formatters.dart';
import 'package:sipeka/features/budget/domain/entities/budget_entity.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/wishlist/domain/entities/wishlist_entity.dart';
import 'package:sipeka/features/wishlist/presentation/controllers/wishlist_provider.dart';

class FinancialSimulatorScreen extends StatefulWidget {
  const FinancialSimulatorScreen({super.key});

  @override
  State<FinancialSimulatorScreen> createState() => _FinancialSimulatorScreenState();
}

class _FinancialSimulatorScreenState extends State<FinancialSimulatorScreen> {
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  
  double _durationMonths = 12.0;
  bool _isLoading = false;
  String _aiResult = "";
  
  double _currentMonthlyIncome = 0.0;
  double _currentMonthlyExpense = 0.0;
  bool _hasCalculatedCurrentStats = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentFinancialStats();
  }

  void _loadCurrentFinancialStats() async {
    try {
      final db = DatabaseHelper.instance;
      final income = await db.getTotalIncomeCurrentMonth();
      final expense = await db.getTotalExpenseCurrentMonth();
      setState(() {
        _currentMonthlyIncome = income;
        _currentMonthlyExpense = expense;
        _hasCalculatedCurrentStats = true;
      });
    } catch (e) {
      debugPrint("Error loading financial stats for simulator: $e");
    }
  }

  void _simulateGoal() async {
    final title = _goalTitleController.text.trim();
    final cleanAmount = _targetAmountController.text.replaceAll('.', '');
    final targetAmount = double.tryParse(cleanAmount) ?? 0.0;
    final duration = _durationMonths.toInt();

    if (title.isEmpty) {
      SipekaNotification.showWarning(context, "Harap masukkan nama barang/impian Anda!");
      return;
    }
    if (targetAmount <= 0) {
      SipekaNotification.showWarning(context, "Harap masukkan target nominal tabungan!");
      return;
    }

    setState(() {
      _isLoading = true;
      _aiResult = "";
    });
    HapticFeedback.mediumImpact();

    try {
      // Pastikan data statistik saat ini sudah siap
      if (!_hasCalculatedCurrentStats) {
        final db = DatabaseHelper.instance;
        _currentMonthlyIncome = await db.getTotalIncomeCurrentMonth();
        _currentMonthlyExpense = await db.getTotalExpenseCurrentMonth();
        _hasCalculatedCurrentStats = true;
      }

      final result = await AiService().simulateFinancialGoal(
        goalTitle: title,
        targetAmount: targetAmount,
        durationMonths: duration,
        currentMonthlyIncome: _currentMonthlyIncome,
        currentMonthlyExpense: _currentMonthlyExpense,
      );

      setState(() {
        _aiResult = result;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("Error running AI simulator: $e");
      if (mounted) {
        SipekaNotification.showWarning(context, "Gagal memproses simulasi. Periksa koneksi internet Anda.");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFinancialPlan() async {
    final title = _goalTitleController.text.trim();
    final cleanAmount = _targetAmountController.text.replaceAll('.', '');
    final targetAmount = double.tryParse(cleanAmount) ?? 0.0;
    final duration = _durationMonths.toInt();

    if (title.isEmpty || targetAmount <= 0) return;

    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    try {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

      // 1. Tambahkan item ke Wishlist
      final String wishlistId = const Uuid().v4();
      final newWishlist = WishlistEntity(
        id: wishlistId,
        title: title,
        targetAmount: targetAmount,
        savedAmount: 0.0,
      );
      await wishlistProvider.addWishlist(newWishlist);

      // 2. Tambahkan atau sesuaikan Anggaran Bulanan otomatis
      final double monthlySavingNeeded = targetAmount / duration;
      final String budgetId = const Uuid().v4();
      final newBudget = BudgetEntity(
        id: budgetId,
        category: "Tabungan $title",
        limit: monthlySavingNeeded,
        iconCode: Icons.savings_rounded.codePoint,
        usedAmount: 0.0,
      );
      await budgetProvider.addBudget(newBudget);

      // Tutup loading dialog
      navigator.pop();

      if (mounted) {
        SipekaNotification.showSuccess(
          context,
          "Rencana diaktifkan! Wishlist baru dibuat & Anggaran bulanan sebesar Rp ${NumberFormat.decimalPattern('id').format(monthlySavingNeeded.toInt())} disiapkan.",
        );
        navigator.pop(); // Kembali ke halaman Wishlist utama
      }
      HapticFeedback.mediumImpact();
    } catch (e) {
      navigator.pop(); // Tutup loading dialog jika terjadi error
      debugPrint("Error applying simulation plan: $e");
      if (mounted) {
        SipekaNotification.showWarning(context, "Gagal menerapkan rencana keuangan otomatis.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.decimalPattern('id');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AI Financial Planner",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFORMASI KEADAAN KEUANGAN SAAT INI (SUMMARY CARD)
            _buildCurrentFinanceCard(formatter, isDark),
            const SizedBox(height: 24),

            // FORM INPUT IMPIAN
            _buildSectionHeader("DETAIL TARGET IMPIAN ANDA"),
            const SizedBox(height: 12),
            TextField(
              controller: _goalTitleController,
              style: GoogleFonts.nunito(),
              decoration: InputDecoration(
                labelText: "Nama Barang / Impian",
                labelStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
                hintText: "Contoh: Laptop Coding, Beli Motor",
                hintStyle: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.nunito(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
              decoration: InputDecoration(
                labelText: "Target Nominal Tabungan",
                labelStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
                prefixText: "Rp ",
                prefixStyle: GoogleFonts.nunito(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("JANGKA WAKTU PENCAPAIAN"),
                Text(
                  "${_durationMonths.toInt()} Bulan",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            Slider(
              value: _durationMonths,
              min: 1.0,
              max: 60.0,
              divisions: 59,
              activeColor: AppColors.primaryBlue,
              inactiveColor: Colors.grey.withValues(alpha: 0.2),
              onChanged: (val) {
                setState(() {
                  _durationMonths = val;
                });
              },
            ),
            const SizedBox(height: 20),

            // TOMBOL SIMULASIKAN
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.psychology_rounded, color: Colors.white),
                label: Text(
                  "SIMULASIKAN VIA AI",
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _isLoading ? null : _simulateGoal,
              ),
            ),
            const SizedBox(height: 28),

            // CARD HASIL ANALISIS AI GEMINI
            _buildSectionHeader("ANALISIS KELAYAKAN SIPEKA AI"),
            const SizedBox(height: 12),
            _buildAiAnalysisCard(isDark),
            const SizedBox(height: 30),

            // TOMBOL TERAPKAN RENCANA
            if (_aiResult.isNotEmpty && !_isLoading)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    "TERAPKAN RENCANA FINANSIAL",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: _applyFinancialPlan,
                ),
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCurrentFinanceCard(NumberFormat formatter, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rata-rata Keuangan Bulan Ini",
            style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pemasukan", style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      "Rp ${formatter.format(_currentMonthlyIncome.toInt())}",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.incomeGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pengeluaran", style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      "Rp ${formatter.format(_currentMonthlyExpense.toInt())}",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.expenseRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiAnalysisCard(bool isDark) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 20),
            Text(
              "AI sedang membaca tren keuangan Anda...",
              style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Text(
              "Menghitung kelayakan tabungan dan merekomendasikan efisiensi anggaran.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_aiResult.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            const Icon(Icons.bubble_chart_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              "Belum ada simulasi",
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              "Silakan ketuk tombol Simulasikan via AI di atas untuk mulai membuat rencana pencapaian impian Anda bersama AI SIPEKA.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, size: 22, color: Colors.purple.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Text(
                "Saran & Analisis Rencana AI",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          MarkdownText(text: _aiResult),
        ],
      ),
    );
  }
}

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarkdownText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final List<TextSpan> spans = [];
    final parts = text.split('**');
    
    bool isBold = false;
    for (var part in parts) {
      if (isBold) {
        spans.add(TextSpan(
          text: part,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else {
        spans.add(TextSpan(text: part));
      }
      isBold = !isBold;
    }

    return RichText(
      text: TextSpan(
        style: style ?? GoogleFonts.nunito(
          fontSize: 12, 
          color: Theme.of(context).textTheme.bodyLarge?.color, 
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}
