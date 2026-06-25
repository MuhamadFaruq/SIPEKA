import 'package:flutter/material.dart';
import 'package:sipeka/core/database/database_helper.dart';
import 'package:sipeka/core/services/ai_service.dart';

class FinancialHealthProvider with ChangeNotifier {
  double _score = 100.0;
  String _status = "Sangat Sehat";
  String _aiAdvice = "Sedang menganalisis kesehatan keuangan Anda...";
  bool _isLoading = false;

  double get score => _score;
  String get status => _status;
  String get aiAdvice => _aiAdvice;
  bool get isLoading => _isLoading;

  Future<void> calculateHealthScore() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;

      // 1. Ambil data keuangan riil dari SQLite
      final income = await db.getTotalIncomeCurrentMonth();
      final expense = await db.getTotalExpenseCurrentMonth();
      final totalDebt = await db.getTotalUnpaidDebt();
      final wallets = await db.getAllWallets();
      
      double totalSavings = wallets.fold(0.0, (sum, item) => sum + (item['initial_balance'] ?? 0.0));

      // Jika data pemasukan belum diinput, berikan skor default aman
      if (income <= 0) {
        _score = 50.0;
        _status = "Butuh Data";
        _aiAdvice = "Silakan catat pemasukan dan pengeluaran bulan ini agar SIPEKA AI dapat memberikan analisis kesehatan keuangan Anda.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Kalkulasi Skor Komponen
      // A. Rasio Tabungan (30%): Target saving rate >= 20%
      double savingRate = (income - expense) / income;
      double savingScore = (savingRate >= 0.2) ? 30.0 : (savingRate > 0 ? (savingRate / 0.2) * 30.0 : 0.0);

      // B. Rasio Hutang (30%): Target debt-to-income <= 30%
      double debtToIncome = totalDebt / income;
      double debtScore = (debtToIncome <= 0.3) ? 30.0 : (debtToIncome > 1.0 ? 0.0 : (1.0 - debtToIncome) / 0.7 * 30.0);

      // C. Dana Darurat (40%): Target dana darurat >= 3 bulan pengeluaran
      double emergencyFundRatio = (expense > 0) ? (totalSavings / expense) : 3.0;
      double emergencyScore = (emergencyFundRatio >= 3.0) ? 40.0 : (emergencyFundRatio / 3.0) * 40.0;

      // 3. Gabungkan total skor
      _score = savingScore + debtScore + emergencyScore;
      if (_score < 0) _score = 0.0;
      if (_score > 100) _score = 100.0;

      // Tentukan status kesehatan
      if (_score >= 80) {
        _status = "Sehat & Stabil";
      } else if (_score >= 60) {
        _status = "Cukup Sehat";
      } else if (_score >= 40) {
        _status = "Waspada Pengeluaran";
      } else {
        _status = "Butuh Perbaikan Keras";
      }

      // 4. Panggil Gemini AI untuk saran kustom yang personal
      final advicePrompt = '''
- Skor Kesehatan Keuangan: ${_score.toStringAsFixed(0)}/100
- Status: $_status
- Pemasukan Bulan Ini: Rp ${income.toInt()}
- Pengeluaran Bulan Ini: Rp ${expense.toInt()}
- Total Tabungan/Saldo Saat Ini: Rp ${totalSavings.toInt()}
- Total Hutang Belum Lunas: Rp ${totalDebt.toInt()}
''';
      
      _aiAdvice = await AiService().getFinancialAdvice(advicePrompt);
    } catch (e) {
      print("Error calculating health score: $e");
      _aiAdvice = "Gagal memuat nasihat finansial. Silakan periksa koneksi internet Anda.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
