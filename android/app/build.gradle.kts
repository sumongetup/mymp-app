import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "bd.mymp.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Fixed for the life of the app: Play ties the listing, the reviews and
        // the signing key to this string and it can never be changed.
        applicationId = "bd.mymp.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    /*
     * The upload key, read from android/key.properties, which is never
     * committed. Without that file the release build falls back to the debug
     * key so `flutter build apk --release` still works on a fresh clone — but
     * Play will not take a debug-signed bundle, and does not have to say why.
     */
    signingConfigs {
        create("upload") {
            val keyFile = rootProject.file("key.properties")
            if (keyFile.exists()) {
                val props = Properties()
                FileInputStream(keyFile).use { props.load(it) }
                storeFile = props.getProperty("storeFile")?.let { rootProject.file(it) }
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            val signed = rootProject.file("key.properties").exists()
            signingConfig = signingConfigs.getByName(if (signed) "upload" else "debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
