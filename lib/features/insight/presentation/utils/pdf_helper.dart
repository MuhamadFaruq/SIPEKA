import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Text, Color;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_entity.dart';
import 'package:sipeka/features/transaction/domain/entities/transaction_type.dart';

class PdfReportHelper {
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF007AFF);
  static const PdfColor primaryDarkBlue = PdfColor.fromInt(0xFF00479E);
  static const PdfColor expenseRed = PdfColor.fromInt(0xFFFF5252);
  static const PdfColor incomeGreen = PdfColor.fromInt(0xFF00C853);
  static const PdfColor neutralGrey = PdfColor.fromInt(0xFFF5F7FF);

  static const List<PdfColor> chartColors = [
    PdfColor.fromInt(0xFF007AFF), // Blue
    PdfColor.fromInt(0xFFFF9500), // Orange
    PdfColor.fromInt(0xFF4CD964), // Green
    PdfColor.fromInt(0xFF5856D6), // Purple
    PdfColor.fromInt(0xFFFF2D55), // Pink
    PdfColor.fromInt(0xFF5AC8FA), // Light Blue
    PdfColor.fromInt(0xFFFFCC00), // Yellow
    PdfColor.fromInt(0xFF8E8E93), // Grey
  ];

  static Future<void> exportMonthlyReport({
    required BuildContext context,
    required DateTime selectedDate,
    required List<Transaction> transactions,
  }) async {
    try {
      final doc = pw.Document();
      final String formattedMonth = DateFormat('MMMM yyyy', 'id_ID').format(selectedDate);
      final String timestamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      // Get user email if signed in
      final user = FirebaseAuth.instance.currentUser;
      final String userEmail = user?.email ?? 'Pengguna SIPEKA';
      final String userName = user?.displayName ?? '';

      // --- 1. DATA PROCESSING ---
      double totalIncome = 0;
      double totalExpense = 0;
      final Map<String, double> categoryExpenses = {};
      final List<Transaction> monthlyTx = [];

      for (var tx in transactions) {
        if (tx.date.year == selectedDate.year && tx.date.month == selectedDate.month) {
          monthlyTx.add(tx);
          if (tx.type == TransactionType.income) {
            totalIncome += tx.amount;
          } else {
            totalExpense += tx.amount;
            categoryExpenses[tx.category] = (categoryExpenses[tx.category] ?? 0.0) + tx.amount;
          }
        }
      }

      double netBalance = totalIncome - totalExpense;

      // Calculate total cumulative balance up to the end of the selected month
      double totalBalance = 0.0;
      try {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        final initialWalletsBalance = walletProvider.wallets.fold(0.0, (sum, w) => sum + w.initialBalance);
        
        final lastDayOfSelectedMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59, 999);
        
        double incomesUpToMonth = 0.0;
        double expensesUpToMonth = 0.0;
        
        for (var tx in transactions) {
          if (tx.date.isBefore(lastDayOfSelectedMonth) || tx.date.isAtSameMomentAs(lastDayOfSelectedMonth)) {
            if (tx.type == TransactionType.income) {
              incomesUpToMonth += tx.amount;
            } else if (tx.type == TransactionType.expense) {
              expensesUpToMonth += tx.amount;
            }
          }
        }
        totalBalance = initialWalletsBalance + incomesUpToMonth - expensesUpToMonth;
      } catch (e) {
        print("Gagal mengambil total saldo kumulatif: $e");
      }

      // Sort categories by expense amount descending
      final sortedCategories = categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Group small categories if there are more than 5
      final List<MapEntry<String, double>> topCategories = [];
      double otherExpensesSum = 0.0;
      for (int i = 0; i < sortedCategories.length; i++) {
        if (i < 4) {
          topCategories.add(sortedCategories[i]);
        } else {
          otherExpensesSum += sortedCategories[i].value;
        }
      }
      if (otherExpensesSum > 0) {
        topCategories.add(MapEntry('Lainnya', otherExpensesSum));
      }

      // Sort chronological for table view
      monthlyTx.sort((a, b) => b.date.compareTo(a.date));

      final currencyFormatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      // Built-in modern fonts
      final fontRegular = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();

      // --- 2. BUILD PDF PAGES ---
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context ctx) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Row(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SIPEKA',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 22,
                          color: primaryBlue,
                        ),
                      ),
                      pw.Text(
                        'Sistem Pencatatan Keuangan',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'LAPORAN KEUANGAN BULANAN',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: primaryDarkBlue,
                        ),
                      ),
                      pw.Text(
                        formattedMonth.toUpperCase(),
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context ctx) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 20),
              padding: const pw.EdgeInsets.only(top: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Dicetak pada $timestamp | SIPEKA',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            return [
              // --- Divider ---
              pw.Container(
                height: 3,
                color: primaryBlue,
                margin: const pw.EdgeInsets.only(bottom: 20),
              ),

              // --- Meta Info ---
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 24),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: neutralGrey,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Pemilik Laporan:',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            userName.isNotEmpty ? '$userName ($userEmail)' : userEmail,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Total Transaksi:',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            '${monthlyTx.length} Transaksi',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Saldo Akhir Bulan:',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            currencyFormatter.format(totalBalance),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: totalBalance >= 0 ? primaryBlue : expenseRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- Section: Ringkasan Finansial (Financial Summary Cards) ---
              pw.Row(
                children: [
                  _buildSummaryCard(
                    title: 'Pemasukan',
                    value: currencyFormatter.format(totalIncome),
                    accentColor: incomeGreen,
                    bgColor: PdfColor.fromInt(0xFFE8F5E9), // Light green
                    fontRegular: fontRegular,
                    fontBold: fontBold,
                  ),
                  pw.SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'Pengeluaran',
                    value: currencyFormatter.format(totalExpense),
                    accentColor: expenseRed,
                    bgColor: PdfColor.fromInt(0xFFFFEBEE), // Light red
                    fontRegular: fontRegular,
                    fontBold: fontBold,
                  ),
                  pw.SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'Arus Kas Bersih',
                    value: currencyFormatter.format(netBalance),
                    accentColor: netBalance >= 0 ? primaryBlue : expenseRed,
                    bgColor: netBalance >= 0 
                        ? PdfColor.fromInt(0xFFE3F2FD) // Light blue
                        : PdfColor.fromInt(0xFFFFEBEE),
                    fontRegular: fontRegular,
                    fontBold: fontBold,
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // --- Section: Charts & Breakdown ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // --- Left Side: Pie Chart (Expense Distribution) ---
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Proporsi Pengeluaran',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: primaryDarkBlue,
                            ),
                          ),
                          pw.SizedBox(height: 16),
                          if (totalExpense == 0)
                            pw.Container(
                              height: 120,
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'Tidak ada data pengeluaran',
                                style: pw.TextStyle(
                                  font: fontRegular,
                                  fontSize: 10,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            )
                          else
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                // Simple Visual Pie/Donut Chart inside PDF using pw.Chart
                                pw.SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: pw.Chart(
                                    grid: pw.PieGrid(),
                                    datasets: List.generate(topCategories.length, (index) {
                                      final entry = topCategories[index];
                                      return pw.PieDataSet(
                                        value: entry.value,
                                        color: chartColors[index % chartColors.length],
                                      );
                                    }),
                                  ),
                                ),
                                pw.SizedBox(width: 12),
                                // Legend for Pie Chart
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: List.generate(topCategories.length, (index) {
                                      final entry = topCategories[index];
                                      final double percentage = totalExpense > 0 
                                          ? (entry.value / totalExpense) * 100 
                                          : 0.0;
                                      return pw.Padding(
                                        padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                                        child: pw.Row(
                                          children: [
                                            pw.Container(
                                              width: 6,
                                              height: 6,
                                              decoration: pw.BoxDecoration(
                                                color: chartColors[index % chartColors.length],
                                                shape: pw.BoxShape.circle,
                                              ),
                                            ),
                                            pw.SizedBox(width: 4),
                                            pw.Expanded(
                                              child: pw.Text(
                                                '${entry.key} (${percentage.toStringAsFixed(0)}%)',
                                                style: pw.TextStyle(
                                                  font: fontRegular,
                                                  fontSize: 8,
                                                  color: PdfColors.grey800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 16),

                  // --- Right Side: Perbandingan Pemasukan vs Pengeluaran ---
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Arus Kas (Masuk vs Keluar)',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: primaryDarkBlue,
                            ),
                          ),
                          pw.SizedBox(height: 16),
                          _buildComparisonBar(
                            label: 'Pemasukan',
                            amount: totalIncome,
                            maxAmount: totalIncome > totalExpense ? totalIncome : totalExpense,
                            color: incomeGreen,
                            formatter: currencyFormatter,
                            fontRegular: fontRegular,
                            fontBold: fontBold,
                          ),
                          pw.SizedBox(height: 14),
                          _buildComparisonBar(
                            label: 'Pengeluaran',
                            amount: totalExpense,
                            maxAmount: totalIncome > totalExpense ? totalIncome : totalExpense,
                            color: expenseRed,
                            formatter: currencyFormatter,
                            fontRegular: fontRegular,
                            fontBold: fontBold,
                          ),
                          pw.SizedBox(height: 8),
                          pw.Divider(color: PdfColors.grey200, height: 1),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            children: [
                              pw.Text(
                                'Laju Tabungan:',
                                style: pw.TextStyle(
                                  font: fontRegular,
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                ),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                totalIncome > 0 
                                    ? '${((totalIncome - totalExpense) / totalIncome * 100).toStringAsFixed(1)}%' 
                                    : '0%',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 9,
                                  color: netBalance >= 0 ? incomeGreen : expenseRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // --- Section Title: Detail Transaksi ---
              pw.Row(
                children: [
                  pw.Container(
                    width: 4,
                    height: 12,
                    color: primaryBlue,
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'Daftar Histori Transaksi',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 13,
                      color: primaryDarkBlue,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // --- Table of Transactions ---
              if (monthlyTx.isEmpty)
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 24),
                  child: pw.Text(
                    'Tidak ada transaksi di bulan ini.',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
                  ),
                )
              else
                pw.Table(
                  columnWidths: const {
                    0: pw.FixedColumnWidth(60),  // Tanggal
                    1: pw.FlexColumnWidth(2.5),  // Deskripsi / Judul
                    2: pw.FlexColumnWidth(1.5),  // Kategori
                    3: pw.FlexColumnWidth(1.2),  // Dompet
                    4: pw.FlexColumnWidth(1.8),  // Jumlah
                  },
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: primaryDarkBlue,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(6),
                          topRight: pw.Radius.circular(6),
                        ),
                      ),
                      children: [
                        _buildTableHeaderCell('Tanggal', fontBold),
                        _buildTableHeaderCell('Judul', fontBold),
                        _buildTableHeaderCell('Kategori', fontBold),
                        _buildTableHeaderCell('Dompet', fontBold),
                        _buildTableHeaderCell('Jumlah', fontBold, alignRight: true),
                      ],
                    ),
                    // Table Rows
                    ...List.generate(monthlyTx.length, (index) {
                      final tx = monthlyTx[index];
                      final bool isEven = index % 2 == 0;
                      final String dateString = DateFormat('dd/MM/yy').format(tx.date);
                      final String formattedAmount = (tx.type == TransactionType.income ? '+ ' : '- ') + 
                          currencyFormatter.format(tx.amount).replaceFirst('Rp ', '');
                      final PdfColor amtColor = tx.type == TransactionType.income ? incomeGreen : expenseRed;

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isEven ? neutralGrey : PdfColors.white,
                        ),
                        children: [
                          _buildTableCell(dateString, fontRegular),
                          _buildTableCell(tx.title, fontRegular, isBold: true),
                          _buildTableCell(tx.category, fontRegular),
                          _buildTableCell(tx.wallet, fontRegular),
                          _buildTableCell(
                            formattedAmount, 
                            fontBold, 
                            color: amtColor, 
                            alignRight: true,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
            ];
          },
        ),
      );

      // --- 3. DISPLAY NATIVE PRINT PREVIEW & SHARING SHEET ---
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'SIPEKA_Laporan_${DateFormat('yyyy_MM').format(selectedDate)}.pdf',
      );
    } catch (e) {
      // Log error & inform screen
      print("Gagal membuat PDF: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengekspor PDF: ${e.toString()}"),
          backgroundColor: const Color(0xFFFF5252), // expenseRed Color
        ),
      );
    }
  }

  static pw.Widget _buildSummaryCard({
    required String title,
    required String value,
    required PdfColor accentColor,
    required PdfColor bgColor,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: accentColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 13,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildComparisonBar({
    required String label,
    required double amount,
    required double maxAmount,
    required PdfColor color,
    required NumberFormat formatter,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    final double fraction = maxAmount > 0 ? (amount / maxAmount) : 0.0;
    // Cap minimum visual width fraction so it's visible if there is some value
    final double visualFraction = (amount > 0 && fraction < 0.08) ? 0.08 : (fraction > 1.0 ? 1.0 : fraction);
    final int fillFlex = (visualFraction * 100).round();
    final int emptyFlex = 100 - fillFlex;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 9,
                color: PdfColors.grey800,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              formatter.format(amount),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: color,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 10,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            children: [
              if (fillFlex > 0)
                pw.Expanded(
                  flex: fillFlex,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                  ),
                ),
              if (emptyFlex > 0)
                pw.Expanded(
                  flex: emptyFlex,
                  child: pw.SizedBox(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, pw.Font font, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: pw.Container(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, 
    pw.Font font, {
    bool isBold = false, 
    PdfColor color = PdfColors.grey900,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: pw.Container(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: 8.5,
            color: color,
          ),
        ),
      ),
    );
  }
}
