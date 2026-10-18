import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipeka/core/services/notifications.dart';
import 'package:sipeka/core/services/notification_service.dart';
import 'package:sipeka/core/theme/theme_provider.dart';

class AppearanceNotificationSettingsScreen extends StatelessWidget {
  const AppearanceNotificationSettingsScreen({super.key});

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
                  color: (isReminderActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReminderActive ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                  color: isReminderActive ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text("Pengingat Harian", style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(
                isReminderActive ? "Aktif: Setiap ${selectedTime.format(context)}" : "Pengingat dimatikan",
                style: GoogleFonts.nunito(fontSize: 11),
              ),
              onTap: isReminderActive
                  ? () async {
                      final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        await prefs.setInt('reminder_hour', picked.hour);
                        await prefs.setInt('reminder_minute', picked.minute);

                        setTileState(() {
                          selectedTime = picked;
                        });

                        await NotificationService.scheduleReminder(hour: picked.hour, minute: picked.minute);
                        if (context.mounted) {
                          SipekaNotification.showSuccess(context, "Jadwal diganti ke ${picked.format(context)}");
                        }
                      }
                    }
                  : null,
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
                    if (context.mounted) {
                      SipekaNotification.showSuccess(context, "Pengingat diaktifkan!");
                    }
                  } else {
                    await NotificationService.cancelAll();
                    if (context.mounted) {
                      SipekaNotification.showWarning(context, "Semua pengingat dihapus.");
                    }
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
        title: Text(
          "Tampilan & Pengingat",
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(context, "Tema Aplikasi"),
          _buildCard(
            context: context,
            child: Consumer<ThemeProvider>(
              builder: (context, theme, child) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (theme.isDarkMode ? Colors.amber : Colors.blue).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      theme.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: theme.isDarkMode ? Colors.amber : Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "Mode Gelap",
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    theme.isDarkMode ? "Tampilan gelap ramah mata malam hari" : "Tampilan terang standar",
                    style: GoogleFonts.nunito(fontSize: 11),
                  ),
                  trailing: Switch(
                    value: theme.isDarkMode,
                    onChanged: (val) => theme.toggleTheme(val),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 25),
          _buildSectionTitle(context, "Notifikasi & Pengingat Catat"),
          _buildCard(
            context: context,
            child: _buildNotificationTile(context),
          ),
        ],
      ),
    );
  }
}
