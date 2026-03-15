plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sipeka"
    
    // UBAH INI: Dari 36 ke 34 agar stabil
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.sipeka"
        
        // ML Kit butuh minimal 21. 
        // Kamu bisa pakai 21 langsung untuk memastikan.
        minSdk = flutter.minSdkVersion
        targetSdk = 34 
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Jika untuk rilis beneran, pastikan nanti ganti ke signingConfigs.release
            signingConfig = signingConfigs.getByName("debug")
            
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
        // Tambahkan ini jika masih error activity
        force("androidx.activity:activity:1.11.0")
        force("androidx.activity:activity-ktx:1.11.0")
    }
}

flutter {
    source = "../.."
}
