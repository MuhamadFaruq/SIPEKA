import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/main.dart';

class SipekaNotification {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, isSuccess: true);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, isSuccess: false);
  }

  static void _show(BuildContext context, String message, {required bool isSuccess}) {
    final activeContext = context.mounted ? context : navigatorKey.currentContext;
    
    if (activeContext == null) {
      debugPrint("DEBUG Notif: activeContext null, notif dibatalkan");
      return;
    }

    debugPrint("DEBUG Notif: menampilkan notif...");

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

    flushbar.show(activeContext);
  }
}