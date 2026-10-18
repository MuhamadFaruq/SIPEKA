import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipeka/core/services/auth_service.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/utils/security_helper.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  Widget _buildCard({required BuildContext context, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 10),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text(
          "Keamanan & Privasi",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startBlue, endBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final prefs = snapshot.data!;
          bool isPinEnabled = prefs.getBool('is_security_enabled') ?? false;
          bool isBiometricEnabled = prefs.getBool('is_biometric_enabled') ?? false;
          bool isAutolockEnabled = prefs.getBool('is_autolock_enabled') ?? true;
          bool isBlurEnabled = prefs.getBool('is_blur_enabled') ?? true;

          return StatefulBuilder(
            builder: (context, setTileState) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionTitle(context, "Akses Aplikasi"),
                  _buildCard(
                    context: context,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isPinEnabled ? Colors.indigo : Colors.grey).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: isPinEnabled ? Colors.indigo : Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            "Kunci PIN",
                            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isPinEnabled ? "Aplikasi terlindungi PIN 6-digit" : "Kunci PIN nonaktif",
                            style: GoogleFonts.nunito(fontSize: 11),
                          ),
                          trailing: Switch(
                            value: isPinEnabled,
                            activeThumbColor: const Color(0xFF007AFF),
                            onChanged: (bool value) async {
                              if (value) {
                                _showSetupPinDialog(context, (success) async {
                                  if (success) {
                                    await prefs.setBool('is_security_enabled', true);
                                    setTileState(() => isPinEnabled = true);
                                  }
                                });
                              } else {
                                bool auth = await AuthService().authenticateWithBiometrics();
                                if (auth) {
                                  await prefs.setBool('is_security_enabled', false);
                                  await prefs.setBool('is_biometric_enabled', false);
                                  setTileState(() {
                                    isPinEnabled = false;
                                    isBiometricEnabled = false;
                                  });
                                  if (context.mounted) {
                                    SipekaNotification.showWarning(context, "Kunci aplikasi dimatikan");
                                  }
                                }
                              }
                            },
                          ),
                        ),
                        if (isPinEnabled) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isBiometricEnabled ? Colors.teal : Colors.grey).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fingerprint_rounded,
                                color: isBiometricEnabled ? Colors.teal : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              "Sidik Jari / Face ID",
                              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isBiometricEnabled ? "Biometrik aktif untuk buka instan" : "Gunakan biometrik untuk buka cepat",
                              style: GoogleFonts.nunito(fontSize: 11),
                            ),
                            trailing: Switch(
                              value: isBiometricEnabled,
                              activeThumbColor: Colors.teal,
                              onChanged: (bool value) async {
                                if (value) {
                                  bool canAuth = await AuthService().authenticateWithBiometrics();
                                  if (canAuth) {
                                    await prefs.setBool('is_biometric_enabled', true);
                                    setTileState(() => isBiometricEnabled = true);
                                    if (context.mounted) {
                                      SipekaNotification.showSuccess(context, "Biometrik diaktifkan!");
                                    }
                                  }
                                } else {
                                  await prefs.setBool('is_biometric_enabled', false);
                                  setTileState(() => isBiometricEnabled = false);
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (isPinEnabled) ...[
                    const SizedBox(height: 25),
                    _buildSectionTitle(context, "Kenyamanan & Privasi Layar"),
                    _buildCard(
                      context: context,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isAutolockEnabled ? Colors.orange : Colors.grey).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                color: isAutolockEnabled ? Colors.orange : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              "Kunci Otomatis (Idle)",
                              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isAutolockEnabled ? "Kunci otomatis saat 15s di latar belakang" : "Kunci otomatis nonaktif",
                              style: GoogleFonts.nunito(fontSize: 11),
                            ),
                            trailing: Switch(
                              value: isAutolockEnabled,
                              activeThumbColor: Colors.orange,
                              onChanged: (bool value) async {
                                await prefs.setBool('is_autolock_enabled', value);
                                setTileState(() => isAutolockEnabled = value);
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isBlurEnabled ? Colors.purple : Colors.grey).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.blur_on_rounded,
                                color: isBlurEnabled ? Colors.purple : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              "Blur di App Switcher",
                              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isBlurEnabled ? "Samarkan isi aplikasi saat berganti aplikasi" : "Tampilan aplikasi terlihat jelas",
                              style: GoogleFonts.nunito(fontSize: 11),
                            ),
                            trailing: Switch(
                              value: isBlurEnabled,
                              activeThumbColor: Colors.purple,
                              onChanged: (bool value) async {
                                await prefs.setBool('is_blur_enabled', value);
                                setTileState(() => isBlurEnabled = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildSectionTitle(context, "Kredensial & Pemulihan"),
                    _buildCard(
                      context: context,
                      child: _buildListTile(
                        context: context,
                        icon: Icons.security_rounded,
                        title: "Ubah PIN & Pertanyaan Pemulihan",
                        subtitle: "Ganti kode keamanan PIN dan pertanyaan rahasia",
                        color: Colors.blueGrey,
                        onTap: () => _showSetupPinDialog(context, (success) {}),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showSetupPinDialog(BuildContext context, Function(bool) onComplete) {
    final pinController = TextEditingController();
    final answerController = TextEditingController();
    String selectedQuestion = "Siapa nama ibu kandung Anda?";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Setel Keamanan",
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    letterSpacing: 10,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    labelText: "Buat PIN 6 Digit",
                    labelStyle: const TextStyle(color: Colors.grey),
                    counterText: "",
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                Text(
                  "Pertanyaan Pemulihan",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardColor,
                  value: selectedQuestion,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13),
                  items: [
                    "Siapa nama ibu kandung Anda?",
                    "Apa nama hewan peliharaan pertama Anda?",
                    "Di kota mana Anda lahir?"
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => selectedQuestion = val!),
                ),
                TextField(
                  controller: answerController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    labelText: "Jawaban Anda",
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: "Jawaban rahasia",
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("BATAL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF)),
              onPressed: () async {
                if (pinController.text.length == 6 && answerController.text.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final hashedPin = SecurityHelper.hashPin(pinController.text);
                  await prefs.setString('app_pin', hashedPin);
                  await AuthService.saveSecurityQuestion(selectedQuestion, answerController.text);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    SipekaNotification.showSuccess(context, "Keamanan diperbarui!");
                  }
                  onComplete(true);
                } else {
                  if (context.mounted) {
                    SipekaNotification.showWarning(context, "Lengkapi PIN (6 digit) dan Jawaban!");
                  }
                }
              },
              child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
