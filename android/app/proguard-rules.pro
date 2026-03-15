# Mencegah R8 menghapus kelas ML Kit Text Recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.android.gms.internal.ml.** { *; }
-dontwarn com.google.mlkit.vision.text.**