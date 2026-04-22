// import 'package:firebase_auth/firebase_auth.dart'; // DIKOMENTARI
// import 'package:google_sign_in/google_sign_in.dart'; // DIKOMENTARI
// import 'package:cloud_firestore/cloud_firestore.dart'; // DIKOMENTARI
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Membuat class User Dummy agar tidak error di bagian pemanggilan User?
class MockUser {
  final String uid;
  final String? displayName;
  final String? email;

  MockUser({required this.uid, this.displayName, this.email});
}

class AuthService {
  // Instance Firebase kita komentari dulu agar tidak mencari library-nya
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  // --- LOGIKA BIOMETRIC (BARU) ---
  
  Future<bool> authenticateWithBiometrics() async {
    try {
      // 1. Cek apakah perangkat mendukung biometric
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        print("Biometric tidak tersedia di perangkat ini.");
        return true; // Jika tidak ada hardware-nya, izinkan masuk (atau minta PIN)
      }

      // 2. Jalankan autentikasi
      return await _localAuth.authenticate(
        localizedReason: 'Gunakan FaceID atau Fingerprint untuk membuka SIPEKA',
        options: const AuthenticationOptions(
          stickyAuth: true,      // Tetap aktif meski app ke background sebentar
          biometricOnly: true,   // Paksa pakai biometric (wajah/jari), bukan PIN HP
        ),
      );
    } on PlatformException catch (e) {
      print("Error Biometric: $e");
      return false;
    }
  }
  // Mendengarkan perubahan status login (Mock Stream)
  // Untuk sementara kita return stream kosong agar aplikasi menganggap belum login
  Stream<MockUser?> get user => Stream.value(null);

  // Fungsi Login Google (VERSI MOCK / LOKAL)
  Future<MockUser?> signInWithGoogle() async {
    try {
      print("Menjalankan simulasi Login Google...");
      
      // Simulasi delay jaringan
      await Future.delayed(const Duration(seconds: 1));

      // Kita buat User buatan agar UI kamu bisa lanjut ke Dashboard
      final MockUser dummyUser = MockUser(
        uid: "user_lokal_123",
        displayName: "User (Lokal)",
        email: "user@sipeka.local",
      );

      print("Login Berhasil (Mode Offline)");
      return dummyUser;
    } catch (e) {
      print("Error Login Dummy: $e");
      return null;
    }
  }

  static Future<void> saveSecurityQuestion(String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_question', question);
    await prefs.setString('security_answer', answer.toLowerCase().trim());
  }

  static Future<bool> verifySecurityAnswer(String answer) async {
    final prefs = await SharedPreferences.getInstance();
    String? savedAnswer = prefs.getString('security_answer');
    return savedAnswer == answer.toLowerCase().trim();
  }

  // Fungsi Logout (VERSI MOCK)
  Future<void> signOut() async {
    print("Logout berhasil (Mode Offline)");
    // Di sini nanti logika untuk menghapus sesi lokal jika diperlukan
  }
}