import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const List<String> _androidWidgetNames = [
    'SaldoWidgetProvider',
    'VoiceWidgetProvider',
    'CameraWidgetProvider',
    'ShortcutWidgetProvider',
  ];

  /// Memperbarui saldo pada widget layar utama HP secara real-time
  static Future<void> updateWidgetData(double totalSaldo) async {
    try {
      final String formattedSaldo = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(totalSaldo);

      // Simpan data di SharedPreferences yang dibagikan dengan Native Android
      await HomeWidget.saveWidgetData<String>('total_saldo', formattedSaldo);
      
      // Memicu native widget untuk memperbarui tampilannya
      for (var name in _androidWidgetNames) {
        await HomeWidget.updateWidget(
          androidName: name,
        );
      }
      debugPrint("Widget saldo diperbarui: $formattedSaldo");
    } catch (e) {
      debugPrint("Gagal memperbarui widget saldo: $e");
    }
  }

  /// Mendapatkan URI peluncuran jika aplikasi dibuka dari klik widget saat tertutup
  static Future<Uri?> getInitiallyLaunchedUri() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint("Error getInitiallyLaunchedUri: $e");
      return null;
    }
  }

  /// Aliran data (Stream) saat widget diklik saat aplikasi di latar belakang/aktif
  static Stream<Uri?> get widgetClickedStream {
    return HomeWidget.widgetClicked;
  }
}
