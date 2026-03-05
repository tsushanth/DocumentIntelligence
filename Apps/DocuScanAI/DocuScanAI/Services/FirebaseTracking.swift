import Foundation
import FirebaseCore
import FirebaseAnalytics

@MainActor
class FirebaseTracking {
    static let shared = FirebaseTracking()

    private init() {}

    func configure() {
        FirebaseApp.configure()

        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(true)
        print("Firebase: Analytics configured")
        #endif
    }

    // MARK: - Subscription Events

    func trackSubscriptionPurchase(productId: String, price: Double, currency: String = "USD") {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterValue: price,
            AnalyticsParameterCurrency: currency
        ])
    }

    func trackSubscriptionStart(productId: String, price: Double, currency: String = "USD") {
        Analytics.logEvent("subscribe", parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterValue: price,
            AnalyticsParameterCurrency: currency
        ])
    }

    // MARK: - Screen Views

    func trackScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
    }

    // MARK: - Content Events

    func trackViewContent(contentId: String, contentType: String = "document") {
        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemID: contentId,
            AnalyticsParameterContentType: contentType
        ])
    }

    // MARK: - Custom Events

    func trackEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
