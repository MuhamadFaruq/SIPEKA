import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRHelper {
  static Future<double?> extractTotal(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    List<double> amounts = [];

    // Perbaikan Regex: Mengabaikan simbol Rp dan menangani kemungkinan karakter non-angka di sekitarnya
    RegExp regExp = RegExp(r'(\d{1,3}(\.\d{3})*(\d+))');

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        // Normalisasi teks: Ubah ke uppercase dan ganti koma menjadi titik
        String text = line.text.toUpperCase().replaceAll(',', '.');
        
        if (text.contains('TOTAL') || text.contains('JUMLAH') || text.contains('BAYAR') || text.contains('DUE')) {
          Iterable<Match> matches = regExp.allMatches(text);
          for (var match in matches) {
            // Hapus titik ribuan agar bisa di-parse sebagai angka murni
            String cleanAmount = match.group(0)!.replaceAll('.', '');
            double? parsed = double.tryParse(cleanAmount);
            if (parsed != null && parsed > 0) {
              amounts.add(parsed);
            }
          }
        }
      }
    }

    await textRecognizer.close();
    
    // Logika: Ambil angka terbesar karena TOTAL biasanya nominal paling besar di nota
    return amounts.isNotEmpty 
        ? amounts.reduce((curr, next) => curr > next ? curr : next) 
        : null;
  }
}