pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // PaywallKit-Android transitively depends on com.github.commandiron:SpinWheelCompose,
        // which is only published on JitPack, not Maven Central.
        maven { url = uri("https://jitpack.io") }
    }
}

rootProject.name = "PDFGeniusAndroid"
include(":app")

// Reuse the portfolio's shared PaywallKit-Android and RatingKit-Android libraries
// instead of re-implementing paywall/rating UI, following the same pattern SecureVox
// uses for RatingKit-Android (see ~/Documents/GitHub/SecureVox/android/settings.gradle.kts).
include(":paywallkit")
project(":paywallkit").projectDir = file("/Users/sushanthtiruvaipati/Documents/GitHub/PaywallKit-Android/paywallkit")

include(":ratingkit")
project(":ratingkit").projectDir = file("/Users/sushanthtiruvaipati/Documents/GitHub/RatingKit-Android/ratingkit")
