import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val releaseRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val requiredSigningKeys = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val signingPropertiesComplete = keystorePropertiesFile.exists() &&
    requiredSigningKeys.all { !keystoreProperties.getProperty(it).isNullOrBlank() }
val releaseStoreFile = keystoreProperties.getProperty("storeFile")?.let(::file)

if (releaseRequested && (!signingPropertiesComplete || releaseStoreFile?.isFile != true)) {
    throw GradleException(
        "Release signing is not configured. Provide android/key.properties with " +
            "keyAlias, keyPassword, storeFile, and storePassword pointing to an existing keystore."
    )
}

android {
    namespace = "iq.riyada.riyada"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        if (signingPropertiesComplete && releaseStoreFile?.isFile == true) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "iq.riyada.riyada"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (signingConfigs.names.contains("release")) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // APK موحّد لكل المعماريات + مكتبات أصلية غير مضغوطة (حجم أكبر واستقرار أفضل على أجهزة متنوعة)
    splits {
        abi {
            isEnable = false
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
