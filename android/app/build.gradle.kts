plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.parres.whitenoise"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "org.parres.whitenoise"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        ndkVersion = "27.0.12077973"
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Configure native ABI compatibility
        // Note: When building with --split-per-abi, don't use abiFilters here
        // as it conflicts with Flutter's ABI splitting mechanism
    }

    // Ensure the jniLibs directory is included in the APK
    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // Disable code shrinking for flutter_rust_bridge compatibility
            isMinifyEnabled = false
            isShrinkResources = false

            // If you re-enable minification, uncomment this line:
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
