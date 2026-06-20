import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; 
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipeka/core/utils/security_helper.dart';
import 'package:sipeka/core/utils/formatters.dart'; 
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/debt/presentation/controllers/debt_provider.dart';
import 'package:sipeka/features/quick_action/presentation/controllers/quick_action_provider.dart';
import 'package:sipeka/features/wishlist/presentation/controllers/wishlist_provider.dart';
import 'package:sipeka/features/quick_action/domain/entities/quick_action_entity.dart';
import 'package:sipeka/core/database/database_helper.dart'; 
import 'package:sipeka/core/services/notifications.dart'; 
import 'package:sipeka/core/services/notification_service.dart';
import 'package:sipeka/core/services/auth_service.dart'; 
import 'package:sipeka/core/theme/theme_provider.dart';
import 'package:sipeka/core/services/sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:sipeka/core/constants/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final Color startBlue = const Color(0xFF007AFF);
  final Color endBlue = const Color(0xFF00479E);

  Widget _buildSecurityTile(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final prefs = snapshot.data!;
        
        bool isPinEnabled = prefs.getBool('is_security_enabled') ?? false;
        bool isBiometricEnabled = prefs.getBool('is_biometric_enabled') ?? false;

        return StatefulBuilder(
          builder: (context, setTileState) {
            return Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isPinEnabled ? Colors.indigo : Colors.grey).withOpacity(0.1),
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
                    isPinEnabled ? "Aplikasi terkunci dengan PIN" : "Keamanan PIN mati",
                    style: GoogleFonts.nunito(fontSize: 11),
                  ),
                  trailing: Switch(
                    value: isPinEnabled,
                    activeColor: const Color(0xFF007AFF),
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
                          SipekaNotification.showWarning(context, "Kunci aplikasi dimatikan");
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
                        color: (isBiometricEnabled ? Colors.teal : Colors.grey).withOpacity(0.1),
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
                      isBiometricEnabled ? "Biometrik aktif" : "Gunakan biometrik untuk buka cepat",
                      style: GoogleFonts.nunito(fontSize: 11),
                    ),
                    trailing: Switch(
                      value: isBiometricEnabled,
                      activeColor: Colors.teal,
                      onChanged: (bool value) async {
                        if (value) {
                          bool canAuth = await AuthService().authenticateWithBiometrics();
                          if (canAuth) {
                            await prefs.setBool('is_biometric_enabled', true);
                            setTileState(() => isBiometricEnabled = true);
                            SipekaNotification.showSuccess(context, "Biometrik diaktifkan!");
                          }
                        } else {
                          await prefs.setBool('is_biometric_enabled', false);
                          setTileState(() => isBiometricEnabled = false);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    context: context,
                    icon: Icons.security_rounded,
                    title: "Ubah PIN & Pertanyaan",
                    subtitle: "Ganti kode keamanan dan pemulihan",
                    color: Colors.blueGrey,
                    onTap: () => _showSetupPinDialog(context, (success) {}),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final prefs = snapshot.data!;
        
        bool isReminderActive = prefs.getBool('daily_reminder_enabled') ?? true;
        int savedHour = prefs.getInt('reminder_hour') ?? 20;
        int savedMinute = prefs.getInt('reminder_minute') ?? 0;
        TimeOfDay selectedTime = TimeOfDay(hour: savedHour, minute: savedMinute);

        return StatefulBuilder(
          builder: (context, setTileState) {
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isReminderActive ? Colors.green : Colors.grey).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReminderActive ? Icons.notifications_active : Icons.notifications_off_outlined,
                  color: isReminderActive ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text("Pengingat Harian", style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(
                isReminderActive ? "Aktif: Setiap ${selectedTime.format(context)}" : "Pengingat dimatikan",
                style: GoogleFonts.nunito(fontSize: 11),
              ),
              onTap: isReminderActive ? () async {
                final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                if (picked != null) {
                  await prefs.setInt('reminder_hour', picked.hour);
                  await prefs.setInt('reminder_minute', picked.minute);
                  
                  setTileState(() {
                    selectedTime = picked;
                  });
                  
                  await NotificationService.scheduleReminder(hour: picked.hour, minute: picked.minute);
                  SipekaNotification.showSuccess(context, "Jadwal diganti ke ${picked.format(context)}");
                }
              } : null,
              trailing: Switch(
                value: isReminderActive,
                activeThumbColor: const Color(0xFF007AFF),
                onChanged: (bool value) async {
                  await prefs.setBool('daily_reminder_enabled', value);
                  
                  setTileState(() {
                    isReminderActive = value;
                  });

                  if (value) {
                    await NotificationService.scheduleReminder(hour: selectedTime.hour, minute: selectedTime.minute);
                    SipekaNotification.showSuccess(context, "Pengingat diaktifkan!");
                  } else {
                    await NotificationService.cancelAll();
                    SipekaNotification.showWarning(context, "Semua pengingat dihapus.");
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFE9E9E9), 
      appBar: AppBar(
        title: Text("Pengaturan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [startBlue, endBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(context, "Profil"),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSettingCard(
                context: context,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: startBlue.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Color(0xFF007AFF)),
                  ),
                  title: Text(
                    themeProvider.userName, 
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                    "Pengguna Lokal SIPEKA", 
                    style: GoogleFonts.nunito(fontSize: 12)
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showEditProfileDialog(context),
                ),
              );
            },
          ),
          
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Akun Cloud"),
          _buildSettingCard(
            context: context,
            child: _buildCloudAccountTile(context),
          ),
          
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Tampilan"),
          _buildSettingCard(
            context: context, 
            child: Consumer<ThemeProvider>(
              builder: (context, theme, child) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (theme.isDarkMode ? Colors.amber : Colors.blue).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: theme.isDarkMode ? Colors.amber : Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text("Mode Gelap", style: GoogleFonts.nunito(fontSize: 14, fontStyle: FontStyle.normal, fontWeight: FontWeight.bold)),
                  subtitle: Text(theme.isDarkMode ? "Nyaman di mata saat malam" : "Tampilan terang standar", style: GoogleFonts.nunito(fontSize: 11)),
                  trailing: Switch(
                    value: theme.isDarkMode,
                    onChanged: (val) => theme.toggleTheme(val),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Data & Privasi"),
          _buildSettingCard(
            context: context, 
            child: Column(
              children: [
                _buildListTile(context: context, icon: Icons.flash_on, title: "Kelola Jalan Pintas", subtitle: "Tambah atau hapus transaksi cepat di Home", color: Colors.orange, onTap: () => _showManageShortcutsDialog(context)),
                const Divider(height: 1),
                _buildNotificationTile(context), 
                const Divider(height: 1),
                _buildListTile(context: context, icon: Icons.cloud_upload_outlined, title: "Ekspor Data", subtitle: "Simpan data ke format CSV", color: Colors.blue, onTap: () => _showExportOptions(context)),
                const Divider(height: 1),
                _buildListTile(context: context, icon: Icons.cloud_sync, title: "Sinkronisasi Cloud", subtitle: "Cadangkan data ke server SIPEKA", color: Colors.blueAccent, onTap: () async {
                  final authService = AuthService();
                  final currentUser = await authService.user.first;

                  if (currentUser == null) {
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_sync, color: Colors.blueAccent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text("Login Diperlukan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Untuk menyimpan data ke Cloud, Anda perlu login dengan akun Google terlebih dahulu.",
                              style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                icon: Image.asset('assets/images/google_logo.png', height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 20)),
                                label: Text("Lanjutkan dengan Google", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.black87)),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (c) => const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    final user = await authService.signInWithGoogle();
                                    if (!context.mounted) return;
                                    Navigator.pop(context); // Tutup loading dialog
                                    if (user != null) {
                                      SipekaNotification.showSuccess(context, "Login berhasil!");
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        if (!context.mounted) return;
                                        _showSyncOptionsDialog(context, user);
                                      });
                                    } else {
                                      SipekaNotification.showWarning(context, "Login dibatalkan.");
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    Navigator.pop(context); // Tutup loading dialog
                                    _showSignInErrorDiagnostics(context, e);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey)),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _showSyncOptionsDialog(context, currentUser);
                  }
                }),
                const Divider(height: 1),
                _buildListTile(context: context, icon: Icons.restore, title: "Reset Semua Data", subtitle: "Menghapus seluruh catatan dari nol", color: Colors.red, onTap: () => _confirmResetDataSafe(context)),
              ],
            ),
          ),
          
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Keamanan"),
          _buildSettingCard(context: context, child: _buildSecurityTile(context)),
          
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Tentang"),
          _buildSettingCard(
            context: context, 
            child: Column(
              children: [
                _buildListTile(context: context, icon: Icons.info_outline, title: "Versi Aplikasi", subtitle: "v1.0.0", color: Colors.grey, onTap: () {}),
                const Divider(height: 1),
                _buildListTile(context: context, icon: Icons.star_border, title: "Beri Rating", subtitle: "Dukung kami di Play Store", color: Colors.amber, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(child: Text("SIPEKA © 2026", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12))),
        ],
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
          title: Text("Setel Keamanan", style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color
          )),
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
                    color: Theme.of(context).textTheme.bodyLarge?.color
                  ),
                  decoration: InputDecoration(
                    labelText: "Buat PIN 6 Digit", 
                    labelStyle: const TextStyle(color: Colors.grey),
                    counterText: "",
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                Text("Pertanyaan Pemulihan", style: TextStyle(
                  fontSize: 12, 
                  color: isDark ? Colors.white70 : Colors.grey, 
                  fontWeight: FontWeight.bold
                )),
                DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardColor,
                  value: selectedQuestion,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13),
                  items: ["Siapa nama ibu kandung Anda?", "Apa nama hewan peliharaan pertama Anda?", "Di kota mana Anda lahir?"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => selectedQuestion = val!),
                ),
                TextField(
                  controller: answerController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: "Jawaban Anda", 
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: "Jawaban rahasia",
                    hintStyle: const TextStyle(color: Colors.white24),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("BATAL", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF)),
              onPressed: () async {
                if (pinController.text.length == 6 && answerController.text.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final hashedPin = SecurityHelper.hashPin(pinController.text);
                  await prefs.setString('app_pin', hashedPin);
                  await AuthService.saveSecurityQuestion(selectedQuestion, answerController.text);
                  
                  Navigator.pop(ctx);
                  SipekaNotification.showSuccess(context, "Keamanan diperbarui!");
                  onComplete(true);
                } else {
                  SipekaNotification.showWarning(context, "Lengkapi PIN (6 digit) dan Jawaban!");
                }
              },
              child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageShortcutsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE9E9E9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return Consumer<QuickActionProvider>(
          builder: (context, provider, child) {
            final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Kelola Jalan Pintas", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (provider.actions.isEmpty)
                    Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text("Belum ada pintasan", style: GoogleFonts.nunito(color: Colors.grey)))
                  else
                    ...provider.actions.map((action) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: startBlue.withOpacity(0.1), child: Icon(action.icon, color: startBlue, size: 20)),
                            title: Text(action.label, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                            subtitle: Text("${currencyFormat.format(action.amount)} • ${action.category}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showAddShortcutForm(context, existingAction: action)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDeleteShortcut(context, action.id)),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: startBlue, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => _showAddShortcutForm(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("TAMBAH PINTASAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteShortcut(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: startBlue),
            onPressed: () { 
              Provider.of<QuickActionProvider>(context, listen: false).removeAction(id);
              Navigator.pop(ctx); 
              SipekaNotification.showWarning(context, "Pintasan dihapus");
            }, 
            child: const Text("HAPUS", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  void _showAddShortcutForm(BuildContext context, {QuickAction? existingAction}) {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final nameController = TextEditingController(text: existingAction?.label);
    final amountController = TextEditingController(text: existingAction != null ? NumberFormat.decimalPattern('id').format(existingAction.amount) : "");
    List<String> categories = budgetProvider.budgets.map((b) => b.category).toList();
    String? selectedCategory = existingAction?.category;
    if (selectedCategory != null && !categories.contains(selectedCategory)) { selectedCategory = null; }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existingAction == null ? "Pintasan Baru" : "Edit Pintasan", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama (Contoh: Parkir)")),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  hint: const Text("Pilih Kategori"),
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val),
                  decoration: const InputDecoration(border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController, 
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                  decoration: const InputDecoration(labelText: "Nominal (Rp)", prefixText: "Rp "),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: startBlue),
              onPressed: () {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty && selectedCategory != null) {
                  final provider = Provider.of<QuickActionProvider>(context, listen: false);
                  String cleanAmount = amountController.text.replaceAll('.', '');
                  double parsedAmount = double.parse(cleanAmount);
                  final selectedBudget = budgetProvider.budgets.firstWhere((b) => b.category == selectedCategory);
                  if (existingAction == null) {
                    provider.addAction(QuickAction(id: const Uuid().v4(), label: nameController.text, icon: IconData(selectedBudget.iconCode, fontFamily: 'MaterialIcons'), category: selectedCategory!, amount: parsedAmount));
                  } else {
                    provider.updateAction(existingAction.id, nameController.text, parsedAmount, selectedCategory!, IconData(selectedBudget.iconCode, fontFamily: 'MaterialIcons'));
                  }
                  Navigator.pop(ctx);
                  SipekaNotification.showSuccess(context, "Pintasan berhasil disimpan!");
                } else {
                  SipekaNotification.showWarning(context, "Lengkapi semua data ya!");
                }
              },
              child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToCSV(BuildContext context, {String type = "ALL"}) async {
    List<List<dynamic>> rows = [];
    String fileName = "laporan_sipeka";
    if (type == "ALL" || type == "TRANSAKSI") {
      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      if (txProvider.transactions.isNotEmpty) {
        rows.add(["DATA TRANSAKSI"]);
        rows.add(["Tanggal", "Judul", "Nominal", "Kategori", "Dompet", "Tipe"]);
        for (var tx in txProvider.transactions) { rows.add([tx.date.toString(), tx.title, tx.amount, tx.category, tx.wallet, tx.type.toString()]); }
        rows.add([]); 
      }
    }
    if (type == "ALL" || type == "HUTANG") {
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      if (debtProvider.debts.isNotEmpty) {
        rows.add(["DATA HUTANG PIUTANG"]);
        rows.add(["Nama", "Nominal", "Tipe", "Status", "Tgl Pinjam", "Tgl Lunas", "Catatan"]);
        for (var d in debtProvider.debts) { rows.add([d.name, d.amount, d.type == 'Borrowed' ? 'Hutang' : 'Piutang', d.isPaid ? "Lunas" : "Belum Lunas", d.date.toString(), d.paidDate?.toString() ?? "-", d.notes ?? "-"]); }
        rows.add([]);
      }
    }
    if (type == "ALL" || type == "ANGGARAN") {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      if (budgetProvider.budgets.isNotEmpty) {
        rows.add(["DATA ANGGARAN"]);
        rows.add(["Kategori", "Batas Limit (Rp)"]);
        for (var b in budgetProvider.budgets) { rows.add([b.category, b.limit]); }
      }
    }
    if (rows.isEmpty) { SipekaNotification.showWarning(context, "Tidak ada data untuk diekspor"); return; }
    try {
      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/${fileName}_${type.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(path)], text: 'Laporan Keuangan SIPEKA ($type)');
      SipekaNotification.showSuccess(context, "Berhasil mengekspor data $type!");
    } catch (e) { SipekaNotification.showWarning(context, "Gagal ekspor: $e"); }
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text("Pilih Data yang Diekspor", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ListTile(leading: const Icon(Icons.all_inclusive, color: Colors.blue), title: const Text("Semua Data (Gabungan)"), onTap: () { Navigator.pop(ctx); _exportToCSV(context, type: "ALL"); }),
          ListTile(leading: const Icon(Icons.receipt_long, color: Colors.green), title: const Text("Hanya Transaksi"), onTap: () { Navigator.pop(ctx); _exportToCSV(context, type: "TRANSAKSI"); }),
          ListTile(leading: const Icon(Icons.handshake_outlined, color: Colors.orange), title: const Text("Hanya Hutang Piutang"), onTap: () { Navigator.pop(ctx); _exportToCSV(context, type: "HUTANG"); }),
          ListTile(leading: const Icon(Icons.pie_chart_outline, color: Colors.purple), title: const Text("Hanya Daftar Anggaran"), onTap: () { Navigator.pop(ctx); _exportToCSV(context, type: "ANGGARAN"); }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final nameController = TextEditingController(text: themeProvider.userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Nama Profil", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController, 
          autofocus: true, 
          decoration: InputDecoration(
            labelText: "Nama Anda", 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: startBlue), 
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                themeProvider.updateName(nameController.text);
                Navigator.pop(ctx);
                SipekaNotification.showSuccess(context, "Nama profil diperbarui!");
              }
            }, 
            child: const Text("SIMPAN", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 10),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );

  Widget _buildSettingCard({required BuildContext context, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildListTile({
    required BuildContext context, 
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20)
      ),
      title: Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle, 
        style: GoogleFonts.nunito(
          fontSize: 11, 
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
        )
      ),
      onTap: onTap,
    );
  }

  Widget _buildCloudAccountTile(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return _buildListTile(
            context: context,
            icon: Icons.cloud_off,
            title: "Belum Terhubung",
            subtitle: "Klik untuk login & cadangkan data",
            color: Colors.orange,
            onTap: () async {
              final auth = AuthService();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
              try {
                final user = await auth.signInWithGoogle();
                if (!context.mounted) return;
                Navigator.pop(context); // Tutup loading dialog
                if (user != null) {
                  SipekaNotification.showSuccess(context, "Selamat datang, ${user.displayName}!");
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Tutup loading dialog
                _showSignInErrorDiagnostics(context, e);
              }
            },
          );
        }

        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null ? const Icon(Icons.person) : null,
          ),
          title: Text(
            user.displayName ?? "Pengguna Google",
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            user.email ?? "",
            style: GoogleFonts.nunito(fontSize: 11),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                SipekaNotification.showWarning(context, "Berhasil logout");
              }
            },
          ),
        );
      },
    );
  }

  void _confirmResetDataSafe(BuildContext context) {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Konfirmasi Hapus Data", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tindakan ini permanen. Ketik 'HAPUS' di bawah untuk melanjutkan:"),
            const SizedBox(height: 15),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: "Ketik HAPUS",
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (confirmController.text == "HAPUS") {
                Navigator.pop(ctx);
                
                await DatabaseHelper.instance.clearAllTables();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); 
                
                if (context.mounted) {
                  Provider.of<TransactionProvider>(context, listen: false).clearAllData();
                  Provider.of<BudgetProvider>(context, listen: false).clearAllData();
                  Provider.of<DebtProvider>(context, listen: false).clearAllData();
                  Provider.of<WishlistProvider>(context, listen: false).clearAllData();
                  
                  SipekaNotification.showSuccess(context, "Semua data telah dihapus!");
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } else {
                SipekaNotification.showWarning(context, "Kata konfirmasi salah.");
              }
            },
            child: const Text("HAPUS SEKARANG", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSyncOptionsDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_sync, color: Colors.blueAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Sinkronisasi Cloud", 
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Akun terhubung: ${user.email}",
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Pilih tindakan sinkronisasi:",
              style: GoogleFonts.nunito(fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 16),
            
            // Tombol BACKUP
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text("Cadangkan ke Cloud (Backup)", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                _runSyncProcess(context, isBackup: true);
              },
            ),
            const SizedBox(height: 10),
            
            // Tombol RESTORE
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text("Pulihkan dari Cloud (Restore)", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                _confirmRestoreDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _confirmRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Konfirmasi Pemulihan Data", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text(
          "Peringatan: Seluruh data transaksi lokal saat ini di handphone ini akan dihapus dan digantikan dengan data cadangan dari server cloud SIPEKA. Tindakan ini tidak dapat dibatalkan.\n\nApakah Anda yakin ingin melanjutkan?",
          style: GoogleFonts.nunito(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _runSyncProcess(context, isBackup: false);
            },
            child: Text("Pulihkan Sekarang", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _runSyncProcess(BuildContext context, {required bool isBackup}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              isBackup ? "Mengunggah data ke Cloud..." : "Mengunduh data dari Cloud...", 
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 14, decoration: TextDecoration.none)
            ),
          ],
        ),
      ),
    );

    try {
      if (isBackup) {
        await SyncService().syncAllData();
        if (!context.mounted) return;
        Navigator.pop(context); // Tutup loading dialog
        SipekaNotification.showSuccess(context, "Data berhasil dicadangkan ke Cloud!");
      } else {
        await SyncService().restoreAllData();
        
        // Refresh Provider lokal agar UI terupdate instan
        if (!context.mounted) return;
        await Provider.of<TransactionProvider>(context, listen: false).fetchAndSetTransactions();
        await Provider.of<BudgetProvider>(context, listen: false).fetchAndSetBudgets();
        await Provider.of<DebtProvider>(context, listen: false).fetchAndSetDebts();
        await Provider.of<WishlistProvider>(context, listen: false).fetchAndSetWishlist();

        if (!context.mounted) return;
        Navigator.pop(context); // Tutup loading dialog
        SipekaNotification.showSuccess(context, "Data berhasil dipulihkan dari Cloud!");
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      SipekaNotification.showWarning(context, "Gagal sinkronisasi: ${e.toString()}");
    }
  }

  void _showSignInErrorDiagnostics(BuildContext context, Object error) {
    String message = error.toString();
    String solution = "Terjadi kesalahan yang tidak dikenal saat menghubungkan ke Google.";

    if (message.contains("10") || message.toLowerCase().contains("developer_error")) {
      solution = "Penyebab Umum: SHA-1 fingerprint dari keystore aplikasi Anda belum didaftarkan di Firebase Console untuk aplikasi Android com.example.sipeka.\n\n"
          "Cara Memperbaiki:\n"
          "1. Generate SHA-1 debug keystore Anda.\n"
          "2. Masuk ke Firebase Console -> Project Settings -> SDK Setup -> Tambahkan fingerprint SHA-1.\n"
          "3. Unduh google-services.json yang baru dan gantikan yang lama di android/app/google-services.json.";
    } else if (message.contains("12500") || message.toLowerCase().contains("sign_in_failed")) {
      solution = "Penyebab Umum: Metode login Google belum diaktifkan di Firebase Console.\n\n"
          "Cara Memperbaiki:\n"
          "1. Masuk ke Firebase Console -> Authentication -> Sign-in method.\n"
          "2. Klik 'Add new provider' -> pilih 'Google'.\n"
          "3. Aktifkan (Enable) dan pilih email dukungan project (Project support email), lalu klik Simpan.";
    } else if (message.contains("7") || message.toLowerCase().contains("network_error")) {
      solution = "Penyebab: Koneksi internet terputus atau tidak stabil. Pastikan perangkat Anda terhubung ke internet dengan baik.";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Google Link Gagal", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Detail Error:",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: GoogleFonts.nunito(fontSize: 12, color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Text(
                "Solusi / Panduan:",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                solution,
                style: GoogleFonts.nunito(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }
}
