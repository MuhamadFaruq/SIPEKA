import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart'; 
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);
  
  final Color colorExpense = const Color(0xFFFF5252);
  final Color colorIncome = const Color(0xFF448AFF);
  final Color colorSavings = const Color(0xFF00C853);

  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context); 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTransactions = transactionProvider.transactions;

    final monthTransactions = allTransactions.where((t) {
      return t.date.year == selectedDate.year && t.date.month == selectedDate.month;
    }).toList();

    final yearTransactions = allTransactions.where((t) {
      return t.date.year == selectedDate.year;
    }).toList();

    final chartData = _processChartData(yearTransactions);
    
    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in monthTransactions) {
      if (t.type == 'Pemasukan' || t.type == 'Income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    double totalSavings = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // FIX: Dinamis
      appBar: AppBar(
        title: Text("Laporan ${selectedDate.year}", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startBlue, endBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMonthSelector(context),
            const SizedBox(height: 16),
            
            _buildChartSection(
              context,
              chartData[0] as List<FlSpot>, 
              chartData[1] as List<FlSpot>, 
              chartData[2] as List<FlSpot>, 
              chartData[3] as double
            ),
            
            const SizedBox(height: 16),
            _buildSmartSummaryCard(context, monthTransactions, totalIncome, totalExpense, totalSavings),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Realisasi Anggaran", 
                style: GoogleFonts.nunito(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).textTheme.bodyLarge?.color
                )),
            ),
            const SizedBox(height: 12),
            
            _buildBudgetList(context, monthTransactions, budgetProvider.budgets),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(BuildContext context, List<Transaction> monthTransactions, List<Budget> budgets) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(20)
      ),
      child: budgets.isEmpty 
        ? Text("Belum ada anggaran", style: GoogleFonts.nunito(color: Colors.grey))
        : Column(
            children: budgets.map((budget) {
              double spentAmount = monthTransactions
                  .where((tx) => tx.category == budget.category && (tx.type == 'Expense' || tx.type == 'Pengeluaran'))
                  .fold(0, (sum, item) => sum + item.amount);

              return Column(
                children: [
                  _buildBudgetItem(context, budget.category, spentAmount, budget.limit),
                  const SizedBox(height: 20)
                ]
              );
            }).toList(),
          ),
    );
  }

  Widget _buildBudgetItem(BuildContext context, String category, double spent, double limit) {
    if (limit == 0) return const SizedBox();

    double percentage = spent / limit;
    Color progressColor = percentage > 0.8 ? const Color(0xFFFF5252) : (percentage > 0.5 ? Colors.amber : const Color(0xFF00C853));
    double visualProgress = percentage > 1.0 ? 1.0 : percentage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category, style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color
            )),
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(spent), 
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color
              )
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 12, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(10))),
            LayoutBuilder(builder: (ctx, constraints) {
              return Container(
                width: constraints.maxWidth * visualProgress,
                height: 12,
                decoration: BoxDecoration(color: progressColor, borderRadius: BorderRadius.circular(10)),
              );
            }),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${(percentage * 100).toInt()}% dari budget", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)),
            Text("Batas: ${NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(limit)}", 
              style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)),
          ],
        ),
        if (percentage > 1.0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Over Budget! (Melebihi Rp ${NumberFormat.decimalPattern('id').format(spent - limit)})",
              style: GoogleFonts.nunito(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ),
      ],
    );
  }

  Widget _buildSmartSummaryCard(BuildContext context, List<Transaction> transactions, double income, double expense, double savings) {
    int totalTx = transactions.length;
    String topCategory = "-";
    if (transactions.isNotEmpty) {
      Map<String, int> categoryFreq = {};
      for (var tx in transactions) {
        if (tx.type != 'Pemasukan' && tx.type != 'Income') {
           categoryFreq[tx.category] = (categoryFreq[tx.category] ?? 0) + 1;
        }
      }
      if (categoryFreq.isNotEmpty) {
        var sortedEntries = categoryFreq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        topCategory = sortedEntries.first.key;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [startBlue, endBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: endBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Pengeluaran Bulan Ini", style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(expense), style: GoogleFonts.nunito(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildSummaryRow("Duit Masuk", income),
                const SizedBox(height: 8),
                _buildSummaryRow("Duit Keluar", expense),
                const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(color: Colors.white30, height: 1)),
                _buildSummaryRow("Sisa Duit", savings, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text("$totalTx transaksi • Top: $topCategory", style: GoogleFonts.nunito(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.nunito(color: Colors.white70, fontSize: 12)), 
      Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value), style: GoogleFonts.nunito(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 12))
    ]);
  }

  Widget _buildMonthSelector(BuildContext context) {
     return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16), onPressed: () => setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month - 1))),
          Text(DateFormat('MMMM yyyy', 'id_ID').format(selectedDate), style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16), onPressed: () => setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month + 1))),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, List<FlSpot> income, List<FlSpot> expense, List<FlSpot> savings, double maxY) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.bar_chart_rounded, color: startBlue, size: 20), const SizedBox(width: 8), Text("Statistik Tahun ${selectedDate.year}", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color))]),
          const SizedBox(height: 30),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false, 
                  horizontalInterval: maxY / 5, 
                  getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.grey[100], strokeWidth: 1)
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                    if (index >= 0 && index < 12 && index % 2 == 0) { 
                         return Padding(padding: const EdgeInsets.only(top: 10.0), child: Text(months[index], style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)));
                    }
                    return const SizedBox();
                  })),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 11, minY: 0, maxY: maxY,
                lineBarsData: [_buildLine(savings, colorSavings), _buildLine(expense, colorExpense), _buildLine(income, colorIncome)],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildLegendItem("Masuk", colorIncome), const SizedBox(width: 16), _buildLegendItem("Keluar", colorExpense), const SizedBox(width: 16), _buildLegendItem("Sisa Duit", colorSavings)]),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots, isCurved: true, preventCurveOverShooting: true, color: color, barWidth: 3, isStrokeCapRound: true,
      dotData: FlDotData(show: true, checkToShowDot: (spot, barData) => spot.y > 0, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: color)),
      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey[600]))]);
  }

  List<dynamic> _processChartData(List<Transaction> transactions) {
    List<double> monthlyIncome = List.filled(12, 0.0);
    List<double> monthlyExpense = List.filled(12, 0.0);
    for (var tx in transactions) {
      int monthIndex = tx.date.month - 1; 
      if (tx.type == 'Pemasukan' || tx.type == 'Income') {
        monthlyIncome[monthIndex] += tx.amount;
      } else {
        monthlyExpense[monthIndex] += tx.amount;
      }
    }
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    List<FlSpot> savingsSpots = [];
    double maxY = 0;
    for (int i = 0; i < 12; i++) {
      double inc = monthlyIncome[i];
      double exp = monthlyExpense[i];
      double sav = inc - exp;
      if (sav < 0) sav = 0;
      incomeSpots.add(FlSpot(i.toDouble(), inc));
      expenseSpots.add(FlSpot(i.toDouble(), exp));
      savingsSpots.add(FlSpot(i.toDouble(), sav));
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    if (maxY == 0) maxY = 100000;
    return [incomeSpots, expenseSpots, savingsSpots, maxY * 1.2]; 
  }
}