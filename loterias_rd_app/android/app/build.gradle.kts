import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val isReleaseSigningTask = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("Release", ignoreCase = true)
}

fun requiredKeystoreProperty(name: String): String {
    val value = keystoreProperties[name] as String?
    if (!isReleaseSigningTask) return value ?: ""
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "Missing android/key.properties. Copy android/key.properties.example to android/key.properties and fill in the Play upload key values."
        )
    }
    if (value.isNullOrBlank()) {
        throw GradleException("Missing '$name' in android/key.properties.")
    }
    return value
}

android {
    namespace = "com.sorteosdominicanos.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sorteosdominicanos.app"
        manifestPlaceholders["appLabel"] = "Sorteos Dominicanos"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = requiredKeystoreProperty("keyAlias")
            keyPassword = requiredKeystoreProperty("keyPassword")
            storePassword = requiredKeystoreProperty("storePassword")
            requiredKeystoreProperty("storeFile").takeIf { it.isNotBlank() }?.let {
                storeFile = file(it)
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appLabel"] = "Sorteos Dominicanos DEV"
        }
        release {
            signingConfig = signingConfigs.getByName("release")

            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
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
