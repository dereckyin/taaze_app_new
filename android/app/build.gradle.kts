plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "tw.taaze.bookstore"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
