import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Firebase / Google Services configuration is intentionally gitignored in this repo.
// If `google-services.json` is not present locally, we skip applying the plugin so
// release builds can still succeed (Firebase/FCM will be disabled at runtime).
val requestedTasks = gradle.startParameter.taskNames.joinToString(" ")
val isReleaseBuild = requestedTasks.contains("Release", ignoreCase = true)
val hasReleaseGoogleServicesJson =
    listOf("src/release/google-services.json", "google-services.json").any { file(it).exists() }

if (isReleaseBuild) {
    if (hasReleaseGoogleServicesJson) {
        apply(plugin = "com.google.gms.google-services")
    } else {
        logger.warn(
            "⚠️  google-services.json is missing for Release. Skipping 'com.google.gms.google-services' plugin; " +
                "Firebase will be disabled. Add android/app/google-services.json (or android/app/src/release/google-services.json) to enable it.",
        )
    }
} else {
    // For non-release tasks (debug/profile), apply if any config exists.
    val hasAnyGoogleServicesJson =
        listOf("src/debug/google-services.json", "src/profile/google-services.json", "google-services.json")
            .any { file(it).exists() }
    if (hasAnyGoogleServicesJson) {
        apply(plugin = "com.google.gms.google-services")
    }
}

android {
    namespace = "tw.taaze.bookstore"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "tw.taaze.bookstore"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "⚠️  android/key.properties not found. Release is signed with debug keys. " +
                        "Run scripts/generate_android_upload_keystore.ps1 before uploading to Play Console.",
                )
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
}
