import Foundation
import FacebookCore
import FacebookAEM

/// Handles Facebook SDK initialization and App Events for Meta Ads attribution
@MainActor
final class FacebookSDKManager {

    static let shared = FacebookSDKManager()

    private let attributionSentKey = "fb_attribution_sent"

    private init() {}

    /// Initializes the Facebook SDK - call this on app launch
    func initialize() {
        // Initialize Facebook SDK
        ApplicationDelegate.shared.initializeSDK()

        // Enable automatic event logging
        Settings.shared.isAutoLogAppEventsEnabled = true

        // Enable advertiser ID collection for attribution
        Settings.shared.isAdvertiserIDCollectionEnabled = true

        // Configure AEM (Aggregated Event Measurement) for iOS 14.5+
        if #available(iOS 14.5, *) {
            AEMReporter.configure(withNetworker: nil, appID: Settings.shared.appID, reporter: nil)
            AEMReporter.enable()
        }

        // Log app activation event
        AppEvents.shared.activateApp()

        // Send attribution data to optimizer
        Task {
            await sendAttributionToOptimizer()
        }
    }

    /// Handles URL opening for Facebook SDK (deep links, deferred deep links)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }

    /// Logs a custom event for conversion tracking
    func logEvent(_ eventName: AppEvents.Name, parameters: [AppEvents.ParameterName: Any]? = nil) {
        if let parameters = parameters {
            AppEvents.shared.logEvent(eventName, parameters: parameters)
        } else {
            AppEvents.shared.logEvent(eventName)
        }
    }

    /// Logs a purchase event for CAPI (Conversions API)
    func logPurchase(amount: Double, currency: String, parameters: [AppEvents.ParameterName: Any]? = nil) {
        AppEvents.shared.logPurchase(amount: amount, currency: currency, parameters: parameters)
    }

    /// Logs subscription start for CAPI
    func logSubscriptionStart(price: Double, currency: String, subscriptionId: String? = nil) {
        var params: [AppEvents.ParameterName: Any] = [
            .currency: currency,
            .contentType: "subscription"
        ]
        if let subscriptionId = subscriptionId {
            params[.contentID] = subscriptionId
        }
        AppEvents.shared.logPurchase(amount: price, currency: currency, parameters: params)
        AppEvents.shared.logEvent(.subscribe, valueToSum: price, parameters: params)
    }

    /// Logs invoice creation event
    func logInvoiceCreated(amount: Double? = nil) {
        var params: [AppEvents.ParameterName: Any] = [:]
        if let amount = amount {
            params[.contentType] = "invoice"
            AppEvents.shared.logEvent(AppEvents.Name("InvoiceCreated"), valueToSum: amount, parameters: params)
        } else {
            AppEvents.shared.logEvent(AppEvents.Name("InvoiceCreated"))
        }
    }

    /// Logs trial start event
    func logTrialStart() {
        AppEvents.shared.logEvent(.startTrial)
    }

    /// Sends attribution data to the ad-optimizer service for CAPI
    private func sendAttributionToOptimizer() async {
        guard !UserDefaults.standard.bool(forKey: attributionSentKey) else {
            return
        }

        guard NetworkMonitor.shared.isConnected else {
            return
        }

        var payload: [String: Any] = [
            "app_id": "com.documentintelligence.invoiceflow",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "platform": "ios",
            "sdk": "facebook"
        ]

        // Get anonymous ID for attribution
        if let anonymousID = AppEvents.shared.anonymousID {
            payload["fb_anonymous_id"] = anonymousID
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)

            var request = URLRequest(url: URL(string: "https://api.documentintelligence.com/v1/attribution/facebook")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                UserDefaults.standard.set(true, forKey: attributionSentKey)
                print("FacebookSDKManager: Successfully sent attribution data")
            }
        } catch {
            print("FacebookSDKManager: Failed to send attribution data: \(error.localizedDescription)")
        }
    }

    /// Resets attribution tracking (for testing purposes)
    func resetAttribution() {
        UserDefaults.standard.removeObject(forKey: attributionSentKey)
    }
}
