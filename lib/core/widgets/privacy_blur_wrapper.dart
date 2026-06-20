import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyBlurWrapper extends StatefulWidget {
  final Widget child;

  const PrivacyBlurWrapper({super.key, required this.child});

  @override
  State<PrivacyBlurWrapper> createState() => _PrivacyBlurWrapperState();
}

class _PrivacyBlurWrapperState extends State<PrivacyBlurWrapper> with WidgetsBindingObserver {
  bool _isBlurred = false;
  bool _isFeatureEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFeatureStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadFeatureStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isFeatureEnabled = prefs.getBool('is_blur_enabled') ?? true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isFeatureEnabled) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (mounted && !_isBlurred) {
        setState(() {
          _isBlurred = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && _isBlurred) {
        setState(() {
          _isBlurred = false;
        });
      }
      _loadFeatureStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFeatureEnabled || !_isBlurred) {
      return widget.child;
    }

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
