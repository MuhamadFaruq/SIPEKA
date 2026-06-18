import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/main.dart';

class SipekaNotification {
  static void showSuccess(BuildContext context, String message) {
    _show(message, isSuccess: true);
  }

  static void showWarning(BuildContext context, String message) {
    _show(message, isSuccess: false);
  }

  // ✅ context parameter tidak dipakai lagi — selalu pakai navigatorKey
  static void _show(String message, {required bool isSuccess}) {
    // Ambil overlay langsung dari root navigator
    final overlayState = navigatorKey.currentState?.overlay;
    
    if (overlayState == null) {
      debugPrint("DEBUG Notif: overlay null, notif dibatalkan");
      return;
    }

    debugPrint("DEBUG Notif: overlay valid, menampilkan notif...");

    final flushbar = Flushbar(
      messageText: Text(
        message,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
        size: 28.0,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(15),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: isSuccess ? const Color(0xFF007AFF) : Colors.orange.shade800,
      leftBarIndicatorColor: isSuccess ? const Color(0xFF00479E) : null,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );

    // ✅ Inject langsung ke overlay root — tidak perlu context screen sama sekali
    flushbar.show(navigatorKey.currentContext!);
  }
}