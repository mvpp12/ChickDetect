import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The release signing key lives outside the project (see android/key.properties,
// which git ignores). Without it — on another PC — release builds fall back to
// the debug key, so building still works but the result cannot update an
// installed copy of the published app.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.chickdetect.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent: changing it later makes Android treat the app as a new one.
        applicationId = "com.chickdetect.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Phones only. The TensorFlow Lite library also ships x86_64 copies
        // (for emulators), which added about 9 MB to the download.
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    // The app runs the model on the CPU and never creates a GPU delegate, so
    // the GPU library (about 4 MB) is left out.
    packaging {
        jniLibs {
            excludes += "**/libtensorflowlite_gpu_jni.so"
            // Flutter resets the ABI filter above, so the emulator copies are
            // also dropped here.
            excludes += "lib/x86_64/**"
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // Release builds normally run "lint vital" over the app and every plugin
    // first. On this 8 GB laptop that step ran Java out of metaspace after
    // twelve minutes; it only reports warnings, so it is skipped here.
    lint {
        checkReleaseBuilds = false
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Keeps TensorFlow Lite classes the shrinker would otherwise strip.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// The current Flutter template's form. The old `kotlinOptions { jvmTarget }`
// block and the separately applied kotlin-android plugin are rejected by
// Android Gradle Plugin 9.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
