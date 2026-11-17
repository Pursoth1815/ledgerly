plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pursoth.loopd"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Whether the store build gets its own id is a pending decision
        // (proposal section 19).
        applicationId = "com.pursoth.loopd"
        // Android 15 is the minimum (CLAUDE.md, ADR 0017).
        minSdk = 35
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Two builds from one code base (ADR 0017). They differ only in
    // configuration, manifests and flavour source sets; personal-only code
    // (SMS, from Phase 3) goes in src/personal.
    flavorDimensions += "distribution"
    productFlavors {
        create("personal") {
            dimension = "distribution"
        }
        create("store") {
            dimension = "distribution"
        }
    }

    buildTypes {
        // Phase 0B spike lab (src/profile). Debuggable apps run Kotlin code
        // slower, which would skew the benchmarks, so the profile build is not
        // debuggable. Flutter still builds Dart in profile mode: it picks the
        // mode from the build type's name.
        getByName("profile") {
            isDebuggable = false
        }
        release {
            // TODO(phase 11): a real signing config. Debug keys for now, so
            // release builds can be produced and checked in CI.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Keystore key wrapping now; streaming file encryption from Phase 5 (ADR 0009).
    // Pinned after checking Maven Central on 2026-11-16.
    implementation("com.google.crypto.tink:tink-android:1.24.0")
    // Argon2id for the backup passphrase (ADR 0009). Only the Phase 0B spike
    // lab uses it so far; it moves to `implementation` with backup.
    "profileImplementation"("org.bouncycastle:bcprov-jdk18on:1.86")

    testImplementation("junit:junit:4.13.2")
}

flutter {
    source = "../.."
}
