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
        apiKey = envKey;
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

  Future<Map<String, dynamic>?> parseVoiceToTransaction(String rawText, List<String> availableCategories) async {
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
      return null;
    }
  }

  Future<String> getFinancialAdvice(String advicePromptContext) async {
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
      return "Terjadi kesalahan saat menghubungi AI Advisor. Silakan coba lagi nanti.";
    }
  }

  ChatSession startFinancialChat(String contextData) {
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
}
