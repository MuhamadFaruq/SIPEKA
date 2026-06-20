import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sipeka/features/bill/domain/entities/bill_entity.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    // FIX KHUSUS: Menggunakan 'dynamic' untuk menangkap objek lalu dikonversi ke String
    final dynamic tzData = await FlutterTimezone.getLocalTimezone();
    
    // Kita paksa jadi String, jika tzData adalah objek TimezoneInfo, 
    // biasanya dia punya method toString() yang mengembalikan nama timezone-nya.
    final String timeZoneName = tzData.toString();
    
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback aman jika String yang dihasilkan tidak valid
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      debugPrint("Timezone fallback ke Jakarta karena: $e");
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
    );
  }

  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleReminder({int hour = 20, int minute = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    String displayUsername = prefs.getString('user_name') ?? "Faruq";

    await _notificationsPlugin.zonedSchedule(
      id: 0, 
      title: 'SIPEKA Reminder 📋',
      body: '$displayUsername, jangan lupa catat pengeluaranmu hari ini ya!',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Reminder harian untuk mencatat transaksi',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    
    debugPrint("Berhasil menjadwalkan pengingat jam $hour:$minute");
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> scheduleBillReminder(BillEntity bill) async {
    await cancelBillReminder(bill.id);

    if (!bill.isActive || !bill.remindMe) return;

    final reminderDate = bill.nextExecutionDate.subtract(const Duration(days: 1));
    final scheduledTime = DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9, 0);
    
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint("Waktu pengingat H-1 untuk bill '${bill.title}' sudah lewat.");
      return;
    }

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: bill.id.hashCode,
        title: 'Tagihan Besok ⏰',
        body: 'Tagihan "${bill.title}" sebesar Rp ${bill.amount.toStringAsFixed(0)} akan jatuh tempo besok.',
        scheduledDate: tzScheduledTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'bill_reminder',
            'Bill Reminder',
            channelDescription: 'Pengingat H-1 jatuh tempo tagihan rutin',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint("Berhasil menjadwalkan pengingat H-1 bill '${bill.title}' pada $tzScheduledTime");
    } catch (e) {
      debugPrint("Gagal menjadwalkan pengingat H-1: $e");
    }
  }

  static Future<void> cancelBillReminder(String billId) async {
    try {
      await _notificationsPlugin.cancel(id: billId.hashCode);
      debugPrint("Membatalkan pengingat untuk bill ID: $billId");
    } catch (e) {
      debugPrint("Gagal membatalkan pengingat: $e");
    }
  }
}