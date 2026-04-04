import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRHelper {
    static Future<double?> extractTotal(String imagePath) async {
    // 1. Validasi File
    final file = File(imagePath);
    if (!await file.exists()) return null;

    // JEDA KRUSIAL: Kasih napas 500ms buat sistem Android setelah kembali dari kamera/crop
    await Future.delayed(const Duration(milliseconds: 500));

    final inputImage = InputImage.fromFilePath(imagePath);
    
    // Gunakan Instance sekali pakai yang hati-hati
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      // Proses ini yang memakan RAM paling besar
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      double? maxAmount;
      // Pakai karakter pemisah baris agar Regex tidak bingung
      String fullText = recognizedText.text.toUpperCase();
      
      // Regex Pertahankan milikmu, sudah oke
      RegExp totalRegex = RegExp(r"(TOTAL|BAYAR|JUMLAH|DUE|AMOUNT)[\s\w]*[:=]*[\s]*([\d\.,]{3,})");
      Iterable<Match> matches = totalRegex.allMatches(fullText);
      List<double> foundAmounts = [];

      if (matches.isNotEmpty) {
        for (var match in matches) {
          String amountStr = match.group(2) ?? "";
          double? parsed = _parseStringAmount(amountStr);
          if (parsed != null) foundAmounts.add(parsed);
        }
      }

      // Fallback jika kata kunci tidak ketemu
      if (foundAmounts.isEmpty) {
        RegExp genericAmount = RegExp(r"([\d\.,]{4,})");
        Iterable<Match> allMatches = genericAmount.allMatches(fullText);
        for (var m in allMatches) {
          double? parsed = _parseStringAmount(m.group(0)!);
          // Filter: angka di atas 500 perak dan di bawah 5 juta
          if (parsed != null && parsed > 500 && parsed < 5000000) { 
            foundAmounts.add(parsed);
          }
        }
      }

      if (foundAmounts.isNotEmpty) {
        // Ambil angka terbesar (asumsi total belanja adalah angka paling besar di struk)
        maxAmount = foundAmounts.reduce((curr, next) => curr > next ? curr : next);
      }

      return maxAmount;
    } catch (e) {
      print("Error OCR SIPEKA: $e");
      return null;
    } finally {
      // Tutup segera
      textRecognizer.close();
    }
  }

  // Helper untuk membersihkan format angka Indonesia (10.000 atau 10,000)
  static double? _parseStringAmount(String text) {
    String clean = text.replaceAll(RegExp(r'[^0-9\.,]'), '');
    
    if (clean.contains('.') && clean.contains(',')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains('.') && clean.split('.').last.length != 2) {
      clean = clean.replaceAll('.', '');
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }
    
    return double.tryParse(clean);
  }
}