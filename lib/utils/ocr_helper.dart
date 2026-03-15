import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRHelper {
  static Future<double?> extractTotal(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    double? maxAmount;
    
    // Gabungkan semua teks menjadi satu string besar agar mudah diproses regex lintas baris
    String fullText = recognizedText.text.toUpperCase();
    
    // 1. Regex untuk mencari pola "TOTAL" diikuti angka (menangani titik/koma)
    // Pola ini mencari kata TOTAL/BAYAR lalu mengambil angka di sekitarnya
    RegExp totalRegex = RegExp(r"(TOTAL|BAYAR|JUMLAH|DUE)[\s\w]*[:=]*[\s]*([\d\.,]{3,})");
    
    Iterable<Match> matches = totalRegex.allMatches(fullText);
    
    List<double> foundAmounts = [];

    if (matches.isNotEmpty) {
      for (var match in matches) {
        String amountStr = match.group(2) ?? "";
        // Bersihkan titik ribuan dan ubah koma desimal menjadi titik
        double? parsed = _parseStringAmount(amountStr);
        if (parsed != null) foundAmounts.add(parsed);
      }
    }

    // 2. Fallback: Jika regex spesifik gagal, cari semua angka besar di nota
    if (foundAmounts.isEmpty) {
      RegExp genericAmount = RegExp(r"([\d\.,]{4,})"); // Cari angka minimal 4 digit (ribuan)
      Iterable<Match> allMatches = genericAmount.allMatches(fullText);
      for (var m in allMatches) {
        double? parsed = _parseStringAmount(m.group(0)!);
        if (parsed != null && parsed < 10000000) { // Limit 10 juta agar tidak ambil NPWP/No Nota
          foundAmounts.add(parsed);
        }
      }
    }

    await textRecognizer.close();

    // Logika SIPEKA: Ambil angka terbesar karena TOTAL biasanya nominal paling besar
    if (foundAmounts.isNotEmpty) {
      maxAmount = foundAmounts.reduce((curr, next) => curr > next ? curr : next);
    }

    return maxAmount;
  }

  // Helper untuk membersihkan format angka Indonesia (10.000 atau 10,000)
  static double? _parseStringAmount(String text) {
    // Hapus karakter non-digit kecuali titik dan koma
    String clean = text.replaceAll(RegExp(r'[^0-9\.,]'), '');
    
    // Logika Indonesia: Jika ada titik dan koma, titik biasanya ribuan
    if (clean.contains('.') && clean.contains(',')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains('.') && clean.split('.').last.length != 2) {
      // Jika titik bukan di posisi desimal (misal 31.200)
      clean = clean.replaceAll('.', '');
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }
    
    return double.tryParse(clean);
  }
}