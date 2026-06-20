import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipeka/features/auth/presentation/screens/pin_screen.dart';
import 'package:sipeka/main.dart';
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

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
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
