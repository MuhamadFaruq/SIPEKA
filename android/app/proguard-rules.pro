# ============================================================
# SIPEKA ProGuard Rules - Lean & Targeted
# ============================================================
# CATATAN: Firebase, Google Play Services & AndroidX sudah
# memiliki consumer rules bawaan di AAR mereka masing-masing.
# Cukup lindungi kelas-kelas yang Flutter sendiri tidak tangani.

# ---- ML Kit Text Recognition (OCR Nota) ----
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }
-dontwarn com.google.mlkit.**

# ---- SQFlite (database lokal) ----
-keep class com.tekartik.sqflite.** { *; }

# ---- Flutter plugin registry ----
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ---- HomeWidget (widget layar utama) ----
-keep class es.antonborri.home_widget.** { *; }

# ---- R8: Hapus debug log di build rilis (hemat CPU user) ----
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# ---- Suppress warnings yang tidak relevan ----
-dontwarn kotlin.**
-dontwarn kotlinx.**