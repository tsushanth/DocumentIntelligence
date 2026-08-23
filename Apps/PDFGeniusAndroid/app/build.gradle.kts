plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
    alias(libs.plugins.compose.compiler)
}

android {
    // NOTE on applicationId: the live iOS PDFGenius family actually ships under
    // com.documentintelligence.pdfgenius (confirmed by reading PDFGeniusApp.swift's
    // runtimeBundleId switch, which branches on "com.documentintelligence.pdfgenius",
    // "com.documentintelligence.docuscan", "com.documentintelligence.invoiceflow").
    // com.kreativekoala.* is this portfolio's *Android* convention instead (Pixora
    // uses com.kreativekoala.pixora; PaywallKit-Android/RatingKit-Android are
    // namespaced com.kreativekoala.*). A repo-wide grep for the literal string
    // "com.kreativekoala.pdfgenius" across InvoiceFlow, Pixora, SecureVox,
    // PaywallKit-Android, PaywallKit-API found ZERO matches, so it does not collide
    // with anything already registered — but it IS a deliberate naming break from
    // the iOS bundle-id family, not a continuation of it. Flagging this for the
    // business decision rather than silently assuming continuity.
    namespace = "com.kreativekoala.pdfgenius"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.kreativekoala.pdfgenius"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            storeFile = file("/Users/sushanthtiruvaipati/Documents/GitHub/AndroidAppKey")
            storePassword = "KashtePhale!9"
            keyAlias = "androidappkey"
            keyPassword = "KashtePhale!9"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false // portfolio guardrail: Android minify NEVER
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlin {
        jvmToolchain(17)
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    // Core
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)

    // Compose
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material.icons.extended)
    implementation(libs.androidx.navigation.compose)

    // Hilt
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    // Room (local persistence for imported/created PDFs — mirrors iOS PDFDocumentItem)
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)

    // DataStore (app-open counters, onboarding flags — mirrors iOS UserDefaults usage
    // in PDFContentView's checkAppOpenPaywall())
    implementation(libs.androidx.datastore.preferences)

    // Networking — reserved for future backend calls (iOS PromoOfferKit/RatingKit talk to
    // paywallkit-api.fly.dev; nothing wired here yet, no real base URL committed)
    implementation(libs.retrofit)
    implementation(libs.retrofit.moshi)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.moshi)
    ksp(libs.moshi.codegen)

    // ML Kit on-device text recognition (OCR tool) — free, no API key, no network call
    // required at runtime once the model is downloaded. Mirrors iOS OCRView's Vision
    // fallback (VNRecognizeTextRequest) for scanned/no-text-layer pages.
    implementation("com.google.mlkit:text-recognition:16.0.1")
    // Lets us `.await()` ML Kit's Play-Services Task inside a suspend function.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.8.1")

    // Google Play Billing (paywall product purchases — PaywallKit-Android's PaywallView
    // renders the UI; a BillingClient still needs to be wired for real purchases, see
    // SubscriptionRepository TODO)
    implementation("com.android.billingclient:billing-ktx:8.0.0")

    // Shared portfolio libraries — reused rather than re-implemented, per house style
    implementation(project(":paywallkit"))
    implementation(project(":ratingkit"))
    implementation("com.google.android.play:review-ktx:2.0.2")

    // Testing
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.ui.test.junit4)

    debugImplementation(libs.androidx.ui.tooling)
    debugImplementation(libs.androidx.ui.test.manifest)
}
