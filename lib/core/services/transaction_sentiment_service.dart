import 'package:shared_preferences/shared_preferences.dart';

class TransactionSentimentService {
  static const String prefix = 'tx_sentiment_';

  /// Menyimpan sentimen emosional transaksi: 'wise' (bijak), 'normal' (wajar), 'impulsive' (boros)
  static Future<void> saveSentiment(String transactionId, String sentiment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$prefix$transactionId', sentiment);
    
    // Simpan agregasi bulanan untuk analisis finansial
    final now = DateTime.now();
    final monthKey = 'sentiment_stats_${now.year}_${now.month}_$sentiment';
    final currentCount = prefs.getInt(monthKey) ?? 0;
    await prefs.setInt(monthKey, currentCount + 1);
  }

  /// Mengambil sentimen emosional transaksi
  static Future<String?> getSentiment(String transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$prefix$transactionId');
  }

  /// Mengambil statistik sentimen bulan berjalan
  static Future<Map<String, int>> getMonthlySentimentStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final wiseKey = 'sentiment_stats_${now.year}_${now.month}_wise';
    final normalKey = 'sentiment_stats_${now.year}_${now.month}_normal';
    final impulsiveKey = 'sentiment_stats_${now.year}_${now.month}_impulsive';

    final wise = prefs.getInt(wiseKey) ?? 0;
    final normal = prefs.getInt(normalKey) ?? 0;
    final impulsive = prefs.getInt(impulsiveKey) ?? 0;

    return {
      'wise': wise,
      'normal': normal,
      'impulsive': impulsive,
      'total': wise + normal + impulsive,
    };
  }
}
