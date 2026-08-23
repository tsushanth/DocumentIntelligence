package com.kreativekoala.pdfgenius

import android.app.Application
import com.kreativekoala.ratingkit.RatingKit
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class PDFGeniusApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Mirrors iOS PDFGeniusApp.init()'s RatingKit.configure(appId: "pdfgenius", ...)
        // and RatingKit.shared.trackAppOpen(). RatingKit-Android's trigger model
        // (trackAppOpen / trackAction / trackPurchase) mirrors the iOS one directly.
        RatingKit.init(this, appId = "pdfgenius_android")

        // TODO(business decision): iOS wires TikTok Events SDK, Facebook SDK, and
        // Apple Search Ads attribution (AttributionService) in PDFGeniusApp.init().
        // Android equivalents (Meta/TikTok Android SDKs, Google Play install
        // referrer / Play Install Referrer API for attribution) are deliberately
        // NOT wired here — those require fresh app-level credentials per platform
        // and are a business/marketing decision, not something to fabricate.

        // TODO(business decision): iOS configures StoreManager.shared.configure(...)
        // (StoreKit 2 via PaywallKit) and PromoOfferKit.configure(...) pointing at
        // https://paywallkit-api.fly.dev with real product IDs
        // (pdfgenius_pro_annual / pdfgenius_pro_monthly). The Android equivalent
        // needs: (1) a Play Console app + real subscription product IDs, and
        // (2) a Google Play Billing client wired to PaywallKit-Android's
        // PaywallManager. Left as TODO in SubscriptionRepository — do not invent
        // product IDs or a RevenueCat/PaywallKit-API project here.
    }
}
