pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // 1. Loader untuk plugin Flutter (Wajib ada satu)
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    
    // 2. Jembatan Gradle Flutter (Ini yang tadi hilang)
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    
    // 3. Android Application Plugin
    id("com.android.application") version "8.11.1" apply false
    
    // 4. Google Services untuk Firebase
    id("com.google.gms.google-services") version "4.3.15" apply false
    
    // 5. Kotlin Plugin
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
