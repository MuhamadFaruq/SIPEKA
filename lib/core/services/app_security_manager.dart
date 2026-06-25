import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipeka/features/auth/presentation/screens/pin_screen.dart';
import 'package:sipeka/core/navigation/navigation_helper.dart';
import 'package:sipeka/core/theme/app_theme.dart';

class AppSecurityManager with WidgetsBindingObserver {
  static final AppSecurityManager instance = AppSecurityManager._internal();

  AppSecurityManager._internal();

  static bool isAuthenticated = false;
  static bool isPinScreenOpen = false;

  DateTime? _backgroundTime;

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isSecurityActive = prefs.getBool('is_security_enabled') ?? false;
    final bool isAutolockEnabled = prefs.getBool('is_autolock_enabled') ?? true;

    // Note: AppLifecycleState.inactive triggers when a dialog, biometric prompt, or file picker opens.
    // Using paused or hidden is much safer to determine if the app actually went to the background.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_backgroundTime == null) {
        _backgroundTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);
        _backgroundTime = null;

        // Auto-lock check:
        // Lock if PIN is active, autolock is enabled, user was already authenticated, 
        // the idle time is >= 15 seconds, and PinScreen is not already showing.
        if (isSecurityActive &&
            isAutolockEnabled &&
            isAuthenticated &&
            !isPinScreenOpen &&
            diff.inSeconds >= 15) {
          
          isAuthenticated = false;
          // Set isPinScreenOpen immediately to prevent double-pushing
          // if resumed fires multiple times quickly.
          isPinScreenOpen = true;

          navigatorKey.currentState?.push(
            SmoothPageRoute(
              child: const PinScreen(isModal: true),
            ),
          );
        }
      }
    }
  }
}
