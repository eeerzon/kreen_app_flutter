import com.android.build.gradle.internal.api.BaseVariantOutputImpl

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // namespace = "com.example.kreenappflutter"
    namespace = "com.kreen.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            storeFile = file("kreen-release.keystore")
            storePassword = "devkreen"
            keyAlias = "kreen"
            keyPassword = "devkreen"
        }
    }


    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        // applicationId = "com.example.kreenappflutter"
        applicationId = "com.kreen.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        //default set ke dev
        manifestPlaceholders["appHost"] = "dev.kreenconnect.com"
        // manifestPlaceholders["appHost"] = "kreenconnect.com"
        // manifestPlaceholders["appHost"] = "bc.kreenconnect.com"
    }

    flavorDimensions += "env"

    productFlavors {
        create("dev") { // Kotlin DSL pakai create()
            manifestPlaceholders["appHost"] = "dev.kreenconnect.com"
        }
        create("live") {
            manifestPlaceholders["appHost"] = "kreenconnect.com"
        }
        create("semilive") {
            manifestPlaceholders["appHost"] = "bc.kreenconnect.com"
        }
    }

    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }

    buildTypes {
        debug {
            // debug tetap pakai debug keystore
        }

        getByName("release") {
          isMinifyEnabled = true
          isShrinkResources = true
          signingConfig = signingConfigs.getByName("release")

          // proguardFiles(
          //     getDefaultProguardFile("proguard-android-optimize.txt"),
          //     "proguard-rules.pro"
          // )
        }
    }

    applicationVariants.all {

        val flavorName = this.flavorName // "dev", "live", "semilive"
    
        val flavorLabel = when (flavorName) {
            "dev" -> "dev"
            "live" -> "live"
            "semilive" -> "bc"
            else -> flavorName
        }

        outputs.all {

            val output = this

            if (output is com.android.build.gradle.internal.api.BaseVariantOutputImpl) {

                output.outputFileName =
                    "Kreen App v${versionName} (${flavorLabel}).apk"
            }
        }
    }
}

dependencies {
    implementation("com.google.android.material:material:1.11.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.10")
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")
    // Stripe Android SDK
    implementation("com.stripe:stripe-android:20.48.6")
    // Include the financial connections SDK to support US bank account as a payment method
    implementation("com.stripe:financial-connections:20.48.6")
}

flutter {
    source = "../.."
}