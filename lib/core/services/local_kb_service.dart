import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class KbArticle {
  final List<String> keywords;
  final String title;
  final String content;

  KbArticle({
    required this.keywords,
    required this.title,
    required this.content,
  });

  factory KbArticle.fromJson(Map<String, dynamic> json) {
    return KbArticle(
      keywords: List<String>.from(json['keywords'] ?? []),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class LocalKbService {
  static final LocalKbService _instance = LocalKbService._internal();
  factory LocalKbService() => _instance;
  LocalKbService._internal();

  List<KbArticle> _articles = [];
  bool _isInitialized = false;

  // General financial keywords fallback in case JSON has limited keywords
  static const List<String> _generalFinanceKeywords = [
    'uang', 'duit', 'keuangan', 'finansial', 'financial', 'gaji', 'income',
    'pendapatan', 'pengeluaran', 'expense', 'saldo', 'balance', 'dompet',
    'rekening', 'tabungan', 'menabung', 'investasi', 'saham', 'crypto',
    'reksadana', 'obligasi', 'emas', 'inflasi', 'bunga', 'pajak', 'tax',
    'transaksi', 'catat', 'biaya', 'ekonomi', 'dana', 'cash', 'paylater',
    'kredit', 'kartu kredit', 'debit', 'angsuran', 'cicilan', 'modal',
    'untung', 'rugi', 'profit', 'loss', 'forex', 'deposito', 'anggaran',
    'budget', 'hutang', 'piutang', 'pinjaman', 'tagihan', 'dana darurat',
    'wishlist', 'berhemat', 'belanja', 'boros'
  ];

  // Greetings keywords to allow normal pleasantries
  static const List<String> _greetingKeywords = [
    'halo', 'hai', 'hello', 'hi', 'pagi', 'siang', 'sore', 'malam',
    'assalamualaikum', 'salam', 'apa kabar', 'how are you',
    'terima kasih', 'makasih', 'thanks', 'thank you',
    'siapa kamu', 'kamu siapa', 'nama kamu', 'what is your name'
  ];

  static Future<void> init() async {
    if (_instance._isInitialized) return;
    try {
      final jsonString = await rootBundle.loadString('assets/financial_kb.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _instance._articles = jsonList.map((json) => KbArticle.fromJson(json)).toList();
      _instance._isInitialized = true;
      print('LocalKbService: Berhasil memuat ${_instance._articles.length} artikel finansial.');
    } catch (e) {
      print('LocalKbService Error: Gagal memuat basis pengetahuan keuangan: $e');
      // Fallback: don't crash, just log.
    }
  }

  /// Memeriksa apakah kueri berhubungan dengan keuangan atau percakapan ramah-tamah (greeting)
  bool isFinanceRelated(String query) {
    final normalized = query.toLowerCase();
    
    // 1. Cek apakah ada kata kunci dari berkas KB
    for (var article in _articles) {
      for (var keyword in article.keywords) {
        if (normalized.contains(keyword.toLowerCase())) {
          return true;
        }
      }
    }

    // 2. Cek kata kunci finansial umum
    for (var keyword in _generalFinanceKeywords) {
      if (normalized.contains(keyword)) {
        return true;
      }
    }

    // 3. Cek kata kunci ramah-tamah / greeting
    for (var keyword in _greetingKeywords) {
      if (normalized.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Mengambil artikel-artikel relevan berdasarkan kueri pengguna
  List<KbArticle> retrieveContext(String query) {
    final normalized = query.toLowerCase();
    final List<KbArticle> matched = [];

    for (var article in _articles) {
      bool isMatched = false;
      for (var keyword in article.keywords) {
        if (normalized.contains(keyword.toLowerCase())) {
          isMatched = true;
          break;
        }
      }
      if (isMatched) {
        matched.add(article);
      }
    }

    return matched;
  }
}
