import Foundation
import FacebookCore
import AppTrackingTransparency

/// Facebook SDK integration for install attribution and event tracking.
final class FacebookHelper {
    static let shared = FacebookHelper()
    
    private init() {}
    
    /// Call once at app launch — initializes Facebook SDK.
    func initialize() {
        Settings.shared.isAdvertiserTrackingEnabled = true
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            didFinishLaunchingWithOptions: nil
        )
        print("[Facebook] SDK initialized")
    }
    
    /// Call after ATT response is received.
    func updateTrackingStatus() {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            Settings.shared.isAdvertiserTrackingEnabled = (status == .authorized)
        }
    }
    
    /// Track a custom event.
    func trackEvent(_ name: String, parameters: [AppEvents.ParameterName: Any] = [:]) {
        AppEvents.shared.logEvent(AppEvents.Name(name), parameters: parameters)
    }
    
    /// Track a purchase event.
    func trackPurchase(amount: Double, currency: String) {
        AppEvents.shared.logPurchase(amount: amount, currency: currency)
    }
}
