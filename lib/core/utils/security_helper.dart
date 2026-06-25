import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// SecurityHelper — Pusat logika keamanan PIN dan autentikasi SIPEKA.
/// Menggunakan SHA-256 untuk hashing sehingga PIN tidak pernah disimpan plaintext.
class SecurityHelper {
  // --- Konstanta Lockout ---
  static const int maxAttempts = 3;
  static const int lockoutDurationSeconds = 30;
  static const String _prefAttemptsKey = 'pin_attempts';
  static const String _prefLockoutKey = 'pin_lockout_until';

  // --- Hashing ---

  /// Hash sebuah string menggunakan SHA-256.
  static String hash(String input) {
    const String salt = "SIPEKA_SECURE_SALT_2024_#\$";
    final bytes = utf8.encode(salt + input.trim().toLowerCase());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash PIN (tidak di-lowercase karena PIN hanya angka).
  static String hashPin(String pin) {
    const String salt = "SIPEKA_PIN_SALT_99!\$";
    final bytes = utf8.encode(salt + pin.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash PIN versi lama (tanpa salt) untuk keperluan migrasi.
  static String hashPinLegacy(String pin) {
    final bytes = utf8.encode(pin.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi PIN input dengan PIN yang sudah di-hash.
  /// Mendukung transisi transparan dari hash lama (unsalted) ke hash baru (salted).
  static Future<bool> verifyPin(String inputPin, String hashedPin) async {
    // 1. Coba hash baru (salted)
    if (hashPin(inputPin) == hashedPin) return true;

    // 2. Coba hash lama (legacy)
    if (hashPinLegacy(inputPin) == hashedPin) {
      // Jika cocok dengan legacy, segera update ke salted untuk keamanan selanjutnya
      final prefs = await SharedPreferences.getInstance();
      final newSaltedHash = hashPin(inputPin);
      await prefs.setString('app_pin', newSaltedHash);
      await prefs.setBool('is_pin_salted', true);
      debugPrint("SIPEKA Security: PIN berhasil di-upgrade ke Salted Hash secara transparan.");
      return true;
    }

    return false;
  }

  /// Hash jawaban versi lama (tanpa salt) untuk migrasi.
  static String hashLegacy(String input) {
    final bytes = utf8.encode(input.trim().toLowerCase());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi jawaban keamanan (case-insensitive, trim whitespace).
  /// Mendukung transisi transparan ke Salted Hash.
  static Future<bool> verifyAnswer(String inputAnswer, String hashedAnswer) async {
    // 1. Coba hash baru
    if (hash(inputAnswer) == hashedAnswer) return true;

    // 2. Coba hash lama
    if (hashLegacy(inputAnswer) == hashedAnswer) {
      // Kita tidak bisa update otomatis di sini karena kita tidak tahu pref mana yang simpan ini
      // tapi kita izinkan lewat.
      return true;
    }
    return false;
  }

  // --- Lockout Management ---

  /// Rekam percobaan gagal. Return true jika sekarang sedang lockout.
  static Future<bool> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    int attempts = (prefs.getInt(_prefAttemptsKey) ?? 0) + 1;
    await prefs.setInt(_prefAttemptsKey, attempts);

    if (attempts >= maxAttempts) {
      final lockoutUntil = DateTime.now()
          .add(const Duration(seconds: lockoutDurationSeconds))
          .millisecondsSinceEpoch;
      await prefs.setInt(_prefLockoutKey, lockoutUntil);
      return true; // Sekarang lockout
    }
    return false;
  }

  /// Reset counter percobaan gagal (dipanggil setelah PIN benar).
  static Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefAttemptsKey);
    await prefs.remove(_prefLockoutKey);
  }

  /// Cek apakah saat ini dalam kondisi lockout.
  /// Return sisa detik lockout, 0 jika tidak lockout.
  static Future<int> getLockoutRemainingSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getInt(_prefLockoutKey) ?? 0;
    if (lockoutUntil == 0) return 0;

    final remaining = lockoutUntil - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      // Lockout sudah selesai, reset
      await prefs.remove(_prefAttemptsKey);
      await prefs.remove(_prefLockoutKey);
      return 0;
    }
    return (remaining / 1000).ceil();
  }

  /// Sisa percobaan yang tersedia sebelum lockout.
  static Future<int> getRemainingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_prefAttemptsKey) ?? 0;
    return (maxAttempts - attempts).clamp(0, maxAttempts);
  }

  // --- Migrasi PIN Lama (Plaintext → Hashed) ---

  /// Cek apakah PIN yang tersimpan masih berupa plaintext (belum di-hash).
  /// SHA-256 selalu 64 karakter hexadecimal. PIN plaintext biasanya 6 digit.
  static bool isPinPlaintext(String storedPin) {
    return storedPin.length != 64;
  }
}
