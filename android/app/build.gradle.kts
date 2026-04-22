plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sipeka"
    
    // Tetap di 36 agar kompatibel dengan metadata library terbaru
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true 
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.sipeka"
        
        // Ganti flutter.minSdkVersion dengan angka langsung 23 untuk kestabilan S21 FE
        minSdk = flutter.minSdkVersion 
        targetSdk = 35 // Target 35 paling pas untuk Android 15 saat ini
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Tambahkan ini secara eksplisit untuk mengatasi NoClassDefFoundError
    implementation("androidx.core:core:1.15.0")
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-ktx:1.9.3")
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.15.0")
        force("androidx.core:core-ktx:1.15.0")
        // Paksa activity juga agar sinkron dengan Edge-to-Edge API 35
        force("androidx.activity:activity:1.9.3")
        force("androidx.activity:activity-ktx:1.9.3")
    }
}

flutter {
    source = "../.."
}
