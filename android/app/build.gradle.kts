plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.azagazpay"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.azagazpay"
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

val nodeExecutable = providers.environmentVariable("NODE_BINARY").orNull
    ?: listOf("/usr/bin/node", "/usr/local/bin/node", "/opt/homebrew/bin/node")
        .firstOrNull { file(it).canExecute() }
    ?: "node"

val startAzagaspayBackend = tasks.register<Exec>("startAzagaspayBackend") {
    group = "azagaspay"
    description = "Starts the local AzagasPay backend before Android debug/profile builds."
    workingDir = rootProject.projectDir.resolve("../azagaspay-backend")
    commandLine(nodeExecutable, "scripts/start-if-needed.js")
}

tasks.matching { it.name == "preDebugBuild" || it.name == "preProfileBuild" }.configureEach {
    dependsOn(startAzagaspayBackend)
}
