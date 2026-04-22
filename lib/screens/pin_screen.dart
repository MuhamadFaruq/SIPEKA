import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/notifications.dart';
import 'main_navigation.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _inputPin = "";
  String _savedPin = "";

  @override
  void initState() {
    super.initState();
    _loadAndAuth();
  }

  void _loadAndAuth() async {
      final prefs = await SharedPreferences.getInstance();
      _savedPin = prefs.getString('app_pin') ?? "123456";
      bool isBiometricActive = prefs.getBool('is_biometric_enabled') ?? false;
    
    if (isBiometricActive) {
      _authenticateBiometrically();
    }
  }

  Future<void> _authenticateBiometrically() async {
    bool success = await AuthService().authenticateWithBiometrics();
    if (success && mounted) _enterApp();
  }

  void _enterApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  void _handleKeyPress(String value) {
    HapticFeedback.lightImpact(); 
    if (_inputPin.length < 6) {
      setState(() => _inputPin += value);
    }
    
    if (_inputPin.length == 6) {
      if (_inputPin == _savedPin) {
        _enterApp();
      } else {
        HapticFeedback.vibrate(); 
        setState(() => _inputPin = "");
        SipekaNotification.showWarning(context, "PIN yang Anda masukkan salah!");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PIN Screen tetap biru sebagai identitas Keamanan
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF2972FF),
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
              "Silakan masukkan 6 digit PIN Anda",
              style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: index < _inputPin.length ? Colors.white : Colors.white24,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 1),
                ),
              )),
            ),
            
            const Spacer(),
            _buildKeypad(),

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
        // FIX: Dialog mengikuti tema (Gelap/Terang)
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
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7)
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
        backgroundColor: Theme.of(context).cardColor, // FIX: Dinamis
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
                await prefs.setString('app_pin', newPinController.text);
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