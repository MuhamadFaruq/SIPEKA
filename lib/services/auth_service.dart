import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/security_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  // --- LOGIKA BIOMETRIC (BARU) ---
  
  Future<bool> authenticateWithBiometrics() async {
    try {
      // 1. Cek apakah perangkat mendukung biometric
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        debugPrint("Biometric tidak tersedia di perangkat ini.");
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
      debugPrint("Error Biometric: $e");
      return false;
    }
  }
  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }
      return user;
    } catch (e) {
      debugPrint("Error Login Firebase: $e");
      return null;
    }
  }

  static Future<void> saveSecurityQuestion(String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_question', question);
    // Hash jawaban sebelum disimpan — tidak pernah simpan teks asli
    await prefs.setString('security_answer', SecurityHelper.hash(answer));
  }

  static Future<bool> verifySecurityAnswer(String answer) async {
    final prefs = await SharedPreferences.getInstance();
    String? savedAnswer = prefs.getString('security_answer');
    if (savedAnswer == null) return false;
    // Dukung jawaban lama (plaintext) DAN jawaban baru (hashed)
    if (savedAnswer.length == 64) {
      // Format baru: bandingkan hash
      return await SecurityHelper.verifyAnswer(answer, savedAnswer);
    } else {
      // Format lama: bandingkan langsung, lalu migrate ke hash
      final isMatch = savedAnswer == answer.toLowerCase().trim();
      if (isMatch) {
        // Migrasi ke format hashed
        await prefs.setString('security_answer', SecurityHelper.hash(answer));
      }
      return isMatch;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    debugPrint("Logout berhasil");
  }
}