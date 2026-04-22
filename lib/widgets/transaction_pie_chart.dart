import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class TransactionPieChart extends StatelessWidget {
  const TransactionPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        // 1. Ambil data pengeluaran saja
        final expenses = provider.transactions
            .where((tx) => tx.type == 'Pengeluaran' || tx.type == 'Expense')
            .toList();

        if (expenses.isEmpty) {
          return Center(
            child: Text(
              "Belum ada data pengeluaran",
              style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        // 2. Hitung total pengeluaran & Kelompokkan per kategori
        double totalExpense = 0;
        Map<String, double> categoryData = {};
        for (var tx in expenses) {
          totalExpense += tx.amount;
          categoryData.update(tx.category, (value) => value + tx.amount,
              ifAbsent: () => tx.amount);
        }

        // 3. Siapkan data section & Legenda
        final colors = [
          const Color(0xFF007AFF), // Blue
          const Color(0xFFFF5252), // Red
          const Color(0xFF00C853), // Green
          const Color(0xFFFFAB40), // Orange
          const Color(0xFF7C4DFF), // Purple
        ];

        List<PieChartSectionData> sections = [];
        List<Widget> legendItems = [];
        int index = 0;

        categoryData.forEach((category, amount) {
          final color = colors[index % colors.length];
          final percentage = (amount / totalExpense * 100).toStringAsFixed(1);

          sections.add(
            PieChartSectionData(
              value: amount,
              title: '', // Kosongkan agar tidak berantakan di dalam donut
              color: color,
              radius: 18,
              showTitle: false,
            ),
          );

          // Tambah item untuk legenda di samping
          legendItems.add(_buildLegendItem(category, percentage, color));
          index++;
        });

        return Row(
          children: [
            // Grafik Donut
            Expanded(
              flex: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 35,
                      sectionsSpace: 2,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Total",
                        style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        NumberFormat.compactCurrency(locale: 'id_ID', symbol: '').format(totalExpense),
                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Legenda di samping
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legendItems,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String title, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$title ($percentage%)",
              style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}