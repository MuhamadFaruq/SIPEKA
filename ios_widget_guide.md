# Panduan Integrasi Widget Layar Utama (iOS / iPhone) untuk SIPEKA

Pada iOS (seperti yang terlihat pada tangkapan layar iPhone Anda), data dari Flutter harus dihubungkan ke widget native menggunakan teknologi **SwiftUI & WidgetKit**. 

Karena konfigurasi target kompilasi iOS disimpan dalam file proyek Xcode (`project.pbxproj`) yang bersifat tertutup, Anda harus mendaftarkan target widget ini secara manual sekali saja melalui Xcode di macOS Anda. Berikut adalah panduan langkah demi langkah yang sangat mudah diikuti:

---

## Langkah 1: Buat Target Widget Baru di Xcode
1. Buka folder proyek SIPEKA Anda, lalu buka file `ios/Runner.xcworkspace` menggunakan aplikasi **Xcode** di Mac Anda.
2. Di bar menu Xcode atas, klik **File > New > Target...**
3. Pada jendela pencarian yang muncul, ketik dan pilih **Widget Extension**, lalu klik **Next**.
4. Isi konfigurasi sebagai berikut:
   * **Product Name:** `SipekaWidgets`
   * **Organization Identifier:** `com.example` (atau samakan dengan bundle ID utama Anda)
   * **Project:** `Runner`
   * **Embed in Application:** `Runner`
   * *Pastikan pilihan "Include Configuration Intent" atau "Include Live Activity" dalam keadaan **tidak dicentang** (uncheck).*
5. Klik **Finish**. Jika muncul dialog aktivasi skema baru (*Activate scheme*), klik **Activate**.

---

## Langkah 2: Aktifkan "App Groups" (Berbagi Memori data)
Agar aplikasi Flutter Anda dapat mengirimkan nominal Saldo Terbaru ke Widget iOS, keduanya harus berada dalam grup memori yang sama menggunakan fitur **App Groups** Apple:
1. Di Xcode, pilih proyek utama **Runner** di panel navigasi kiri paling atas.
2. Pilih tab **Signing & Capabilities** di bagian tengah.
3. Klik tombol **`+ Capability`** di pojok kiri atas tab tersebut, ketik **App Groups**, lalu klik dua kali untuk menambahkannya.
4. Klik tombol `+` di bawah tabel App Groups baru Anda, masukkan nama grup baru: **`group.com.example.sipeka`** (Ganti `com.example.sipeka` dengan Bundle Identifier aplikasi Anda jika berbeda).
5. Sekarang, pilih target **SipekaWidgets** di kolom target kiri.
6. Lakukan hal yang sama: tambahkan capability **App Groups** dan centang/tambahkan nama grup yang sama persis: **`group.com.example.sipeka`**.

---

## Langkah 3: Tempel Kode SwiftUI Widget
Di panel navigasi Xcode kiri, Anda akan melihat folder baru bernama `SipekaWidgets`. Buka file **`SipekaWidgets.swift`** di dalamnya, hapus semua kode bawaan template Xcode, lalu tempel kode Swift premium berikut:

```swift
import WidgetKit
import SwiftUI

// 1. Model Data yang dibagikan dari Flutter
struct SipekaWidgetEntry: TimelineEntry {
    let date: Date
    let saldo: String
}

// 2. Provider data untuk Widget
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SipekaWidgetEntry {
        SipekaWidgetEntry(date: Date(), saldo: "Rp 0")
    }

    func getSnapshot(in context: Context, completion: @escaping (SipekaWidgetEntry) -> ()) {
        let entry = getLatestEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getLatestEntry()
        // Widget akan diperbarui saat aplikasi dibuka/mengirim data baru
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    private func getLatestEntry() -> SipekaWidgetEntry {
        // Ganti dengan App Group ID Anda yang sama dengan di Xcode
        let sharedDefaults = UserDefaults(suiteName: "group.com.example.sipeka")
        let saldo = sharedDefaults?.string(forKey: "total_saldo") ?? "Rp 0"
        return SipekaWidgetEntry(date: Date(), saldo: saldo)
    }
}

// ==========================================
// WIDGET 1: WIDGET SALDO CEPAT
// ==========================================
struct SaldoWidgetView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total Saldo SIPEKA")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.7))
            
            Text(entry.saldo)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "007AFF"), Color(hex: "00479E")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct SaldoWidget: Widget {
    let kind: String = "SaldoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SaldoWidgetView(entry: entry)
                .containerBackground(.fill(LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "007AFF"), Color(hex: "00479E")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )), for: .widget)
        }
        .configurationDisplayName("SIPEKA - Saldo Cepat")
        .description("Pantau saldo terkini dompet dan e-wallet Anda.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ==========================================
// WIDGET 2: WIDGET PINTASAN SUARA (MIC)
// ==========================================
struct VoiceWidgetView : View {
    var body: some View {
        VStack(spacing: 6) {
            Text("🎙️")
                .font(.system(size: 24))
            Text("Suara")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "007AFF"))
        // Link untuk memicu deep link ke Flutter
        .widgetURL(URL(string: "sipeka://widget/voice"))
    }
}

struct VoiceWidget: Widget {
    let kind: String = "VoiceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { _ in
            VoiceWidgetView()
                .containerBackground(Color(hex: "007AFF"), for: .widget)
        }
        .configurationDisplayName("SIPEKA - Pintasan Suara")
        .description("Pintasan cepat untuk mencatat transaksi menggunakan suara.")
        .supportedFamilies([.systemSmall])
    }
}

// ==========================================
// WIDGET 3: WIDGET PINTASAN NOTA (KAMERA)
// ==========================================
struct CameraWidgetView : View {
    var body: some View {
        VStack(spacing: 6) {
            Text("📸")
                .font(.system(size: 24))
            Text("Nota")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "007AFF"))
        .widgetURL(URL(string: "sipeka://widget/camera"))
    }
}

struct CameraWidget: Widget {
    let kind: String = "CameraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { _ in
            CameraWidgetView()
                .containerBackground(Color(hex: "007AFF"), for: .widget)
        }
        .configurationDisplayName("SIPEKA - Pintasan Nota")
        .description("Pintasan cepat untuk memindai nota transaksi belanja Anda.")
        .supportedFamilies([.systemSmall])
    }
}

// ==========================================
// WIDGET 4: WIDGET JALAN PINTAS (BOLT)
// ==========================================
struct ShortcutWidgetView : View {
    var body: some View {
        VStack(spacing: 6) {
            Text("⚡")
                .font(.system(size: 24))
            Text("Pintas")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "007AFF"))
        .widgetURL(URL(string: "sipeka://widget/shortcut"))
    }
}

struct ShortcutWidget: Widget {
    let kind: String = "ShortcutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { _ in
            ShortcutWidgetView()
                .containerBackground(Color(hex: "007AFF"), for: .widget)
        }
        .configurationDisplayName("SIPEKA - Jalan Pintas")
        .description("Pintasan cepat untuk membuat transaksi dari daftar jalan pintas.")
        .supportedFamilies([.systemSmall])
    }
}

// ==========================================
// BUNDLE UTAMA: MENDAFTARKAN KE-4 WIDGET
// ==========================================
@main
struct SipekaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SaldoWidget()
        VoiceWidget()
        CameraWidget()
        ShortcutWidget()
    }
}

// Ekstensi helper warna Hex di Swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## Langkah 4: Aktifkan App Group di Sisi Flutter (Dart)
Untuk memastikan data dikirim ke App Group yang sama pada iOS, kita harus menambahkan pendaftaran App Group ID tersebut di berkas `main.dart` Anda.
Buka berkas `lib/main.dart` Anda, dan tambahkan pendaftaran App Group setelah inisialisasi `home_widget`:

```dart
// Di dalam main.dart, cari NotificationService.init() dan tambahkan:
await HomeWidget.setAppGroupId('group.com.example.sipeka');
```

---

## Langkah 5: Jalankan Aplikasi
1. Colok iPhone Anda ke Mac atau jalankan iOS Simulator.
2. Di Xcode, pastikan target skema aktif adalah **Runner** (bukan SipekaWidgets), lalu jalankan aplikasi (**Cmd + R**).
3. Setelah aplikasi terbuka, silakan kembali ke Home Screen iPhone, tekan lama pada area kosong, klik tombol **`+`** di pojok kiri atas untuk menambah widget.
4. Cari aplikasi **Sipeka**, Anda akan menemukan **4 pilihan widget terpisah** yang siap dipasang secara individu!
