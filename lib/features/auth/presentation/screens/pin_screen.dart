import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:sipeka/core/services/auth_service.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/utils/security_helper.dart';
import 'package:sipeka/features/dashboard/presentation/screens/main_navigation.dart';
import 'package:sipeka/core/services/app_security_manager.dart';
import 'package:sipeka/core/theme/app_theme.dart';

class PinScreen extends StatefulWidget {
  final bool isModal;

  const PinScreen({super.key, this.isModal = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _inputPin = "";
  String _savedHashedPin = "";
  bool _isLocked = false;
  int _lockoutSeconds = 0;
  int _remainingAttempts = SecurityHelper.maxAttempts;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    AppSecurityManager.isPinScreenOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndAuth();
    });
  }

  @override
  void dispose() {
    AppSecurityManager.isPinScreenOpen = false;
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _loadAndAuth() async {
    final prefs = await SharedPreferences.getInstance();
    String storedPin = prefs.getString('app_pin') ?? "";

    if (storedPin.isNotEmpty) {
      if (SecurityHelper.isPinPlaintext(storedPin)) {
        final hashedPin = SecurityHelper.hashPin(storedPin);
        await prefs.setString('app_pin', hashedPin);
        storedPin = hashedPin;
        debugPrint("SIPEKA Security: PIN Plaintext dimigrasi ke Salted Hash.");
      }
    }

    _savedHashedPin = storedPin;

    final lockoutRemaining = await SecurityHelper.getLockoutRemainingSeconds();
    if (lockoutRemaining > 0) {
      _startLockoutCountdown(lockoutRemaining);
    } else {
      final remaining = await SecurityHelper.getRemainingAttempts();
      if (mounted) setState(() => _remainingAttempts = remaining);
    }

    bool isBiometricActive = prefs.getBool('is_biometric_enabled') ?? false;
    if (isBiometricActive && lockoutRemaining == 0) {
      _authenticateBiometrically();
    }
  }

  void _startLockoutCountdown(int seconds) {
    if (!mounted) return;
    setState(() {
      _isLocked = true;
      _lockoutSeconds = seconds;
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = await SecurityHelper.getLockoutRemainingSeconds();
      if (remaining <= 0) {
        timer.cancel();
        final attempts = await SecurityHelper.getRemainingAttempts();
        if (mounted) {
          setState(() {
            _isLocked = false;
            _lockoutSeconds = 0;
            _remainingAttempts = attempts;
          });
        }
      } else {
        if (mounted) setState(() => _lockoutSeconds = remaining);
      }
    });
  }

  Future<void> _authenticateBiometrically() async {
    bool success = await AuthService().authenticateWithBiometrics();
    if (success && mounted) _enterApp();
  }

  void _enterApp() {
    SecurityHelper.resetAttempts();
    if (!mounted) return;
    AppSecurityManager.isAuthenticated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.isModal) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            SmoothPageRoute(child: const MainNavigation()),
          );
        }
      }
    });
  }

  void _handleKeyPress(String value) async {
    if (_isLocked) return;
    HapticFeedback.lightImpact();
    if (_inputPin.length < 6) {
      setState(() => _inputPin += value);
    }

    if (_inputPin.length == 6) {
      if (_savedHashedPin.isEmpty) {
        _enterApp();
        return;
      }

      if (await SecurityHelper.verifyPin(_inputPin, _savedHashedPin)) {
        _enterApp();
      } else {
        HapticFeedback.vibrate();
        setState(() => _inputPin = "");

        final isNowLocked = await SecurityHelper.recordFailedAttempt();
        if (isNowLocked) {
          final lockoutSec = await SecurityHelper.getLockoutRemainingSeconds();
          _startLockoutCountdown(lockoutSec);
          if (mounted) {
            SipekaNotification.showWarning(
              context,
              "Terlalu banyak percobaan! Coba lagi dalam ${lockoutSec}s.",
            );
          }
        } else {
          final remaining = await SecurityHelper.getRemainingAttempts();
          if (mounted) {
            setState(() => _remainingAttempts = remaining);
            SipekaNotification.showWarning(
              context,
              "PIN salah. Sisa percobaan: $remaining",
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF1A4BB3) : const Color(0xFF2972FF),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_person_rounded, size: 70, color: Colors.white),
            const SizedBox(height: 15),
            Text(
              "Keamanan SIPEKA",
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              _isLocked
                  ? "Terkunci selama $_lockoutSeconds detik"
                  : "Silakan masukkan 6 digit PIN Anda",
              style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
            ),
            if (!_isLocked && _remainingAttempts < SecurityHelper.maxAttempts)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Sisa percobaan: $_remainingAttempts",
                  style: GoogleFonts.nunito(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _isLocked
                      ? Colors.white12
                      : (index < _inputPin.length ? Colors.white : Colors.white24),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 1),
                ),
              )),
            ),

            const Spacer(),
            _isLocked
                ? _buildLockoutIndicator()
                : _buildKeypad(),

            if (!_isLocked)
              TextButton(
                onPressed: () => _handleForgotPassword(context),
                child: Text(
                  "Lupa PIN?",
                  style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLockoutIndicator() {
    return Column(
      children: [
        const Icon(Icons.timer_outlined, color: Colors.white54, size: 48),
        const SizedBox(height: 12),
        Text(
          "$_lockoutSeconds",
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
        ),
        Text(
          "detik tersisa",
          style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          if (index == 9) {
            return IconButton(
              icon: const Icon(Icons.face_unlock_rounded, color: Colors.white, size: 30),
              onPressed: _authenticateBiometrically,
            );
          }
          if (index == 10) return _buildKeyItem("0");
          if (index == 11) {
            return IconButton(
              icon: const Icon(Icons.backspace_rounded, color: Colors.white, size: 24),
              onPressed: () {
                if (_inputPin.isNotEmpty) {
                  setState(() => _inputPin = _inputPin.substring(0, _inputPin.length - 1));
                }
              },
            );
          }
          return _buildKeyItem("${index + 1}");
        },
      ),
    );
  }

  Widget _buildKeyItem(String val) {
    return InkWell(
      onTap: () => _handleKeyPress(val),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        alignment: Alignment.center,
        child: Text(
          val,
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _handleForgotPassword(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String question = prefs.getString('security_question') ?? "Pertanyaan keamanan belum diatur.";
    final answerController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Pemulihan PIN", style: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color
        )),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question, style: GoogleFonts.nunito(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7)
              )),
              const SizedBox(height: 10),
              TextField(
                controller: answerController,
                autofocus: true,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Jawaban Anda",
                  hintStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("BATAL", style: GoogleFonts.nunito(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2972FF)),
            onPressed: () async {
              bool isCorrect = await AuthService.verifySecurityAnswer(answerController.text);
              if (!context.mounted) return;
              if (isCorrect) {
                Navigator.pop(ctx);
                _showResetPinDialog();
              } else {
                SipekaNotification.showWarning(context, "Jawaban Anda salah, silakan coba lagi.");
              }
            },
            child: const Text("VERIFIKASI", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetPinDialog() {
    final newPinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Setel PIN Baru", style: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color
        )),
        content: TextField(
          controller: newPinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 10,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color
          ),
          decoration: InputDecoration(
            hintText: "000000",
            hintStyle: const TextStyle(color: Colors.grey),
            counterText: "",
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (newPinController.text.length == 6) {
                final prefs = await SharedPreferences.getInstance();
                final hashedPin = SecurityHelper.hashPin(newPinController.text);
                await prefs.setString('app_pin', hashedPin);
                await SecurityHelper.resetAttempts();
                if (!context.mounted) return;
                Navigator.pop(ctx);
                SipekaNotification.showSuccess(context, "PIN Berhasil diperbarui!");
                _enterApp();
              }
            },
            child: const Text("SIMPAN & MASUK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
