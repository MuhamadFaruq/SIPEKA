import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipeka/core/utils/security_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '184071946564-6s40uc9deh2c49s7m3iapm8c27uqvora.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        debugPrint("Biometric tidak tersedia di perangkat ini.");
        return true; 
      }

      return await _localAuth.authenticate(
        localizedReason: 'Gunakan FaceID atau Fingerprint untuk membuka SIPEKA',
        options: const AuthenticationOptions(
          stickyAuth: true,      
          biometricOnly: true,   
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
      rethrow;
    }
  }

  static Future<void> saveSecurityQuestion(String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_question', question);
    await prefs.setString('security_answer', SecurityHelper.hash(answer));
  }

  static Future<bool> verifySecurityAnswer(String answer) async {
    final prefs = await SharedPreferences.getInstance();
    String? savedAnswer = prefs.getString('security_answer');
    if (savedAnswer == null) return false;
    if (savedAnswer.length == 64) {
      return await SecurityHelper.verifyAnswer(answer, savedAnswer);
    } else {
      final isMatch = savedAnswer == answer.toLowerCase().trim();
      if (isMatch) {
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
