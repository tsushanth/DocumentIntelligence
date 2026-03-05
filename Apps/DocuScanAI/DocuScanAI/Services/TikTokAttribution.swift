import Foundation
import TikTokBusinessSDK
import AppTrackingTransparency

@MainActor
class TikTokAttribution {
    static let shared = TikTokAttribution()
    private static let tiktokAppId = "7610965168582918152"

    private init() {}

    func configure() {
        guard let config = TikTokConfig(
            appId: Bundle.main.bundleIdentifier ?? "com.documentintelligence.docuscan",
            tiktokAppId: Self.tiktokAppId
        ) else {
            #if DEBUG
            print("TikTok: Failed to create config")
            #endif
            return
        }

        #if DEBUG
        config.enableDebugMode()
        #endif
        // Automatic tracking is enabled by default (installs, launches, retention, purchases)
        config.setDelayForATTUserAuthorizationInSeconds(30)

        TikTokBusiness.initializeSdk(config)

        #if DEBUG
        print("TikTok: SDK initialized with appId \(Self.tiktokAppId)")
        #endif
    }

    func requestTrackingPermission() {
        if #available(iOS 14.5, *) {
            TikTokBusiness.requestTrackingAuthorization { status in
                #if DEBUG
                print("TikTok: ATT status = \(status)")
                #endif
            }
        }
    }

    // MARK: - Subscription Events

    func trackSubscriptionPurchase(productId: String, price: Double, currency: String = "USD") {
        TikTokBusiness.trackEvent("Purchase", withProperties: [
            "content_id": productId,
            "value": price,
            "currency": currency
        ])
    }

    func trackSubscriptionStart(productId: String) {
        TikTokBusiness.trackEvent("Subscribe", withProperties: [
            "content_id": productId
        ])
    }

    // MARK: - Content Events

    func trackViewContent(contentId: String) {
        TikTokBusiness.trackEvent("ViewContent", withProperties: [
            "content_id": contentId
        ])
    }
}
