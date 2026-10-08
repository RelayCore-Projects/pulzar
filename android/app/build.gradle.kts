import java.io.FileInputStream
import java.util.Properties

// Aláírás (ADR-006): a kulcs adatai a CI-ban környezeti változókból jönnek (GitHub Secrets),
// helyi fordításnál opcionálisan az android/key.properties fájlból. Egyik sem kerül a repóba.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}

fun signingValue(property: String, env: String): String? =
    (keystoreProperties.getProperty(property) ?: System.getenv(env))?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("storeFile", "PULZAR_KEYSTORE_PATH")

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "hu.relaycore.pulzar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Végleges azonosító – SOHA ne változtasd meg, különben a frissítés nem települ a régi verzióra
        applicationId = "hu.relaycore.pulzar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // NFR-08: Android 8.0
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseStoreFile != null) {
                storeFile = file(releaseStoreFile)
                storePassword = signingValue("storePassword", "PULZAR_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "PULZAR_KEY_ALIAS")
                // PKCS12 kulcstárnál a kulcs jelszava azonos a tár jelszavával
                keyPassword = signingValue("keyPassword", "PULZAR_KEY_PASSWORD") ?: storePassword
            }
        }
    }

    buildTypes {
        release {
            // Ha nincs megadva kulcs (pl. helyi próbafordítás), a debug kulccsal ír alá
            signingConfig = if (releaseStoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
