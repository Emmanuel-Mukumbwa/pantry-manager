plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

import com.android.build.gradle.internal.api.BaseVariantOutputImpl

android {
    namespace = "com.arelic.pantrymanager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.arelic.pantrymanager"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // APK renaming – works with AGP 8.x
    applicationVariants.all {
        outputs.forEach { output ->
            (output as BaseVariantOutputImpl).outputFileName = "aRelic_pantrymanager_${name}.apk"
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