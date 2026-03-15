import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRHelper {
  static Future<double?> extractTotal(String imagePath) async {
    // 1. Validasi File
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    
    try {
      // Baris ini yang paling berat dan sering bikin crash jika gambar > 5MB
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      double? maxAmount;
      String fullText = recognizedText.text.toUpperCase();
      
      // Regex kamu sudah bagus, kita pertahankan
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

      // Fallback
      if (foundAmounts.isEmpty) {
        RegExp genericAmount = RegExp(r"([\d\.,]{4,})");
        Iterable<Match> allMatches = genericAmount.allMatches(fullText);
        for (var m in allMatches) {
          double? parsed = _parseStringAmount(m.group(0)!);
          // Filter angka masuk akal untuk pengeluaran harian
          if (parsed != null && parsed > 500 && parsed < 5000000) { 
            foundAmounts.add(parsed);
          }
        }
      }

      if (foundAmounts.isNotEmpty) {
        maxAmount = foundAmounts.reduce((curr, next) => curr > next ? curr : next);
      }

      return maxAmount;
    } catch (e) {
      print("Error OCR SIPEKA: $e");
      return null;
    } finally {
      // WAJIB ditutup agar tidak memory leak
      await textRecognizer.close();
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