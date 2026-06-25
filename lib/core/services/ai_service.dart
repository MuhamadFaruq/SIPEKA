import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  late final String _apiKey;
  late final GenerativeModel _model;
  
  AiService() {
    String apiKey = '';
    try {
      final envKey = dotenv.env['GEMINI_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        apiKey = envKey.trim();
      }
    } catch (e) {
      // Fallback safely if dotenv is not initialized
      print('AiService: DotEnv not initialized. Using fallback key. Error: $e');
    }
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  void validateApiKey() {
    if (_apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak ditemukan. Harap tambahkan GEMINI_API_KEY ke file .env Anda.');
    }
  }

  static String formatError(dynamic error) {
    if (error == null) return "Gagal terhubung dengan AI Konsultan. Silakan coba beberapa saat lagi.";
    
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('quota') || 
        errorStr.contains('limit') || 
        errorStr.contains('429')) {
      return "Batas penggunaan konsultasi AI telah tercapai untuk saat ini. Silakan coba beberapa saat lagi.";
    }
    
    if (errorStr.contains('timeout') || 
        errorStr.contains('future not completed')) {
      return "Koneksi terputus karena jaringan lambat atau kurang stabil. Silakan periksa internet Anda dan coba lagi.";
    }
    
    if (errorStr.contains('api key') || 
        errorStr.contains('key not found') || 
        errorStr.contains('api_key') || 
        errorStr.contains('invalid api key')) {
      return "Layanan AI Konsultan sedang tidak tersedia untuk sementara waktu. Silakan coba beberapa saat lagi.";
    }
    
    return "Gagal terhubung dengan AI Konsultan. Silakan periksa koneksi internet Anda atau coba beberapa saat lagi.";
  }

  Future<Map<String, dynamic>?> parseVoiceToTransaction(String rawText, List<String> availableCategories) async {
    validateApiKey();
    try {
      final prompt = '''
Anda adalah AI Financial Assistant. Tugas Anda adalah mengekstrak data transaksi dari ucapan pengguna ke dalam format JSON.
Ucapan pengguna: "$rawText"
Kategori yang tersedia: ${availableCategories.isNotEmpty ? availableCategories.join(', ') : 'Belum ada kategori khusus, gunakan kategori umum seperti Makan, Transport, Belanja, Lainnya'}

Aturan:
1. Kembalikan HANYA JSON object dengan key: "title" (String), "amount" (Number), dan "category" (String).
2. "title" adalah nama barang/transaksi (singkat dan jelas).
3. "amount" adalah nominal uang dalam angka (tanpa pemisah ribuan).
4. "category" harus dipilih dari "Kategori yang tersedia" yang paling cocok. Jika tidak ada yang cocok, gunakan "Lainnya" atau kategori terdekat.
5. Jangan tambahkan markdown seperti ```json atau penjelasan apapun. HANYA JSON format yang valid.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 15));
      
      if (response.text != null) {
        String jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        
        final decoded = jsonDecode(jsonText.trim());
        return decoded as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error parsing voice with AI: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> parseOcrTextToTransaction(String rawText, List<String> availableCategories) async {
    validateApiKey();
    try {
      final prompt = '''
Anda adalah AI Financial Assistant. Tugas Anda adalah menganalisis teks hasil pemindaian OCR dari struk/nota belanja dan mengekstrak total nominal belanja serta kategorinya.
Teks OCR:
"$rawText"

Kategori yang tersedia: ${availableCategories.isNotEmpty ? availableCategories.join(', ') : 'Belum ada kategori khusus, gunakan kategori umum seperti Makan, Transport, Belanja, Lainnya'}

Aturan:
1. Kembalikan HANYA JSON object dengan key: "amount" (Number, total pengeluaran belanja/grand total), dan "category" (String, kategori yang paling cocok dari daftar).
2. Jika tidak ada nominal yang terdeteksi, kembalikan key "amount" bernilai null atau 0.
3. Jangan tambahkan markdown seperti ```json atau penjelasan apapun. HANYA JSON format yang valid.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 15));
      if (response.text != null) {
        String jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        
        final decoded = jsonDecode(jsonText.trim());
        return decoded as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error parsing OCR text with AI: $e');
      return null; // Return null so caller can do fallback safely
    }
  }

  Future<List<Map<String, dynamic>>?> parseReceiptToItems(String rawOcrText) async {
    validateApiKey();
    try {
      final prompt = '''
Anda adalah AI Kasir yang bertugas merapikan struk belanja. Ekstrak data struk hasil OCR berikut menjadi format JSON Array terstruktur.
Teks OCR:
"$rawOcrText"

Aturan:
1. Kembalikan HANYA JSON Array berisi object dengan key: "name" (String, nama makanan/barang singkat) dan "price" (Number, harga bersih setelah diskon jika ada).
2. Jangan masukkan baris subtotal, pajak, biaya layanan, atau diskon umum ke dalam array. Fokus hanya pada item-item belanja utama yang dibeli.
3. Jangan berikan penjelasan, kata pengantar, atau pembungkus markdown seperti ```json. HANYA kembalikan JSON Array yang valid.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 15));
      
      if (response.text != null) {
        String jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        
        final decoded = jsonDecode(jsonText.trim()) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    } catch (e) {
      print('Error parsing receipt to items via Gemini: $e');
      return null;
    }
  }

  Future<double?> parseOcrTextToAmount(String rawText) async {
    validateApiKey();
    try {
      final prompt = '''
Anda adalah AI Financial Assistant. Tugas Anda adalah menganalisis teks hasil pemindaian OCR dari struk/nota belanja dan mengekstrak total nominal belanja (grand total).
Teks OCR:
"$rawText"

Aturan:
1. Kembalikan HANYA JSON object dengan key: "amount" (Number, total pengeluaran belanja/grand total).
2. Jika tidak ada nominal yang terdeteksi, kembalikan key "amount" bernilai null atau 0.
3. Jangan tambahkan markdown seperti ```json atau penjelasan apapun. HANYA JSON format yang valid.
''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 15));
      if (response.text != null) {
        String jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        
        final decoded = jsonDecode(jsonText.trim());
        final amt = decoded['amount'];
        if (amt != null) {
          return (amt as num).toDouble();
        }
      }
      return null;
    } catch (e) {
      print('Error parsing OCR text to amount with AI: $e');
      return null;
    }
  }

  Future<String> getFinancialAdvice(String advicePromptContext) async {
    validateApiKey();
    try {
      final prompt = '''
Anda adalah AI Financial Advisor yang santai, solutif, dan suportif.
Kondisi keuangan pengguna saat ini:
$advicePromptContext

Berikan nasihat keuangan singkat, praktis, dan kasual untuk pengguna. Jangan terlalu panjang, maksimal 2-3 paragraf.
Gunakan bahasa Indonesia yang natural dan ramah.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 20));
      
      return response.text?.trim() ?? "Maaf, saya sedang tidak bisa memberikan nasihat saat ini. Tetap semangat mengatur keuangan!";
    } catch (e) {
      print('Error getting financial advice: $e');
      rethrow;
    }
  }

  Future<String> simulateFinancialGoal({
    required String goalTitle,
    required double targetAmount,
    required int durationMonths,
    required double currentMonthlyIncome,
    required double currentMonthlyExpense,
  }) async {
    validateApiKey();
    try {
      final prompt = '''
Anda adalah AI Financial Planner Indonesia yang sangat ahli dan logis.
Pengguna memiliki impian finansial berikut:
- Nama Impian: "$goalTitle"
- Target Nominal: Rp${targetAmount.toStringAsFixed(0)}
- Jangka Waktu: $durationMonths bulan
- Pendapatan Bulanan Saat Ini: Rp${currentMonthlyIncome.toStringAsFixed(0)}
- Pengeluaran Bulanan Saat Ini: Rp${currentMonthlyExpense.toStringAsFixed(0)}

Berdasarkan data keuangan riil di atas, hitunglah kelayakan impian tersebut secara matematis dan berikan rekomendasi aksi konkret.
Struktur output saran Anda harus berisi:
1. **Analisis Kelayakan**: Apakah realistis dicapai dengan sisa pendapatan bulanan saat ini (Pemasukan - Pengeluaran)? Berapa nominal yang wajib ditabung per bulan (Target / Durasi)?
2. **Rekomendasi Pemangkasan Anggaran**: Sebutkan 2-3 contoh pos pengeluaran yang sebaiknya dipotong atau dihemat beserta estimasi nominalnya.
3. **Rencana Aksi SIPEKA**: Sarankan pengguna untuk membuat Wishlist baru dan mengubah Budget bulanan mereka di aplikasi.

Jawab dengan gaya penulisan yang ramah, profesional, ringkas, dan memotivasi menggunakan Bahasa Indonesia yang natural. Maksimal 3 paragraf pendek. Gunakan format markdown tebal (*) untuk poin-poin penting.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 15));
      return response.text?.trim() ?? "Gagal merumuskan simulasi. Harap periksa koneksi internet Anda.";
    } catch (e) {
      print('Error in financial simulation: $e');
      return "Terjadi kesalahan saat memproses simulasi Anda. Silakan coba beberapa saat lagi.";
    }
  }

  ChatSession startFinancialChat(String contextData) {
    validateApiKey();
    final chatModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
Anda adalah AI Financial Consultant bernama SIPEKA AI. Anda ramah, solutif, dan ahli dalam mengelola keuangan pribadi.
Konteks keuangan pengguna saat ini:
$contextData

Tugas Anda adalah membantu pengguna menjawab pertanyaan mereka tentang keuangan pribadi, memberikan saran penghematan, perencanaan anggaran, atau membantu mereka merumuskan strategi tabungan.
Gunakan bahasa Indonesia yang kasual, santai, dan mudah dimengerti. Singkat, padat, dan jelas.
'''),
    );
    return chatModel.startChat();
  }

  Future<Map<String, dynamic>?> parseTransactionNotification({
    required String notificationText,
    required List<String> availableCategories,
    required List<String> availableWallets,
  }) async {
    validateApiKey();
    try {
      final prompt = '''
Anda adalah AI Financial Tracker yang bertugas menganalisis teks notifikasi dari aplikasi bank atau e-wallet (seperti GoPay, OVO, ShopeePay, Dana, BCA, Mandiri, dll.) dan mengekstrak rincian transaksi keuangan secara terstruktur ke dalam format JSON.

Teks Notifikasi:
"$notificationText"

Daftar Kategori yang Tersedia:
${availableCategories.join(', ')}

Daftar Dompet/Akun Keuangan yang Tersedia:
${availableWallets.join(', ')}

Aturan Analisis:
1. Tentukan apakah ini notifikasi transaksi keuangan yang valid (pengeluaran uang, belanja, transfer keluar, transfer masuk, cashout, top up, atau penerimaan uang). Jika BUKAN notifikasi transaksi keuangan, kembalikan key "isValid" bernilai false.
2. Ekstrak informasi berikut ke dalam JSON object:
   - "isValid": boolean (true jika notifikasi transaksi keuangan yang valid, false jika tidak)
   - "type": String ("EXPENSE" untuk pengeluaran, "INCOME" untuk pemasukan, atau "UNKNOWN")
   - "amount": Number (nominal transaksi, tanpa pemisah ribuan)
   - "merchant": String (nama merchant, toko, aplikasi, penerima transfer, atau pengirim transfer, singkat dan padat)
   - "category": String (kategori yang paling cocok dari daftar Kategori yang Tersedia. Jika tidak ada yang cocok, pilih kategori terdekat seperti Belanja, Makan, Transportasi, atau Lainnya)
   - "wallet": String (dompet yang paling cocok dari daftar Dompet yang Tersedia. Bandingkan secara pintar, misal jika teks menyebut "GoPay" atau "GOPAY" cocokkan dengan "GoPay", "BCA" cocokkan dengan "BCA", dll. Jika tidak ada yang cocok, gunakan "Tunai" atau "Dompet Utama")
   - "description": String (ringkasan penjelasan transaksi singkat, misal: "Pembayaran GrabFood" atau "Transfer masuk dari Budi")
3. HANYA kembalikan JSON object yang valid. Jangan tambahkan markdown seperti ```json atau teks penjelasan apa pun.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(const Duration(seconds: 15));
      if (response.text != null) {
        String jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }
        
        final decoded = jsonDecode(jsonText.trim());
        return decoded as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error parsing notification text with AI: $e');
      return null;
    }
  }
}
