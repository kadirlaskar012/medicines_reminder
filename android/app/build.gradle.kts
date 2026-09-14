import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mediremind.app.medicines_reminder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mediremind.app.medicines_reminder"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties.getProperty("keyAlias") ?: "mediremind-release-key"
            val keyPasswordVal = keystoreProperties.getProperty("keyPassword") ?: "MediRemind@Prod2026!SecureKey"
            val storePasswordVal = keystoreProperties.getProperty("storePassword") ?: "MediRemind@Prod2026!SecureKey"
            val storeFileProp = keystoreProperties.getProperty("storeFile")

            keyAlias = keyAliasVal
            keyPassword = keyPasswordVal
            storePassword = storePasswordVal

            val resolvedFile = when {
                storeFileProp != null && rootProject.file(storeFileProp).exists() -> rootProject.file(storeFileProp)
                storeFileProp != null && file(storeFileProp).exists() -> file(storeFileProp)
                rootProject.file("../release-keystore/mediremind-release.jks").exists() -> rootProject.file("../release-keystore/mediremind-release.jks")
                file("../../release-keystore/mediremind-release.jks").exists() -> file("../../release-keystore/mediremind-release.jks")
                else -> rootProject.file("../release-keystore/mediremind-release.jks")
            }
            storeFile = resolvedFile
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
