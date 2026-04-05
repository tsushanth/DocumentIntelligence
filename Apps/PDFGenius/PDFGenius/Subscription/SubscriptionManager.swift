import SwiftUI
import PaywallKit

// MARK: - Product IDs

enum ProductID: String, CaseIterable {
    case proMonthly = "pdfgenius_pro_monthly"
    case proAnnual = "pdfgenius_pro_annual"
    case proLifetime = "pdfgenius_pro_lifetime"

    var isSubscription: Bool {
        switch self {
        case .proMonthly, .proAnnual:
            return true
        case .proLifetime:
            return false
        }
    }

    static var allIDs: [String] {
        allCases.map(\.rawValue)
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable {
    case free
    case pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }
}

// MARK: - Subscription Manager (StoreKit 2 via PaywallKit)

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var subscriptionTier: SubscriptionTier = .free

    private let store = StoreManager.shared

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let subscriptionTier = "com.pdfgenius.subscription.tier"
        static let subscriptionExpiration = "com.pdfgenius.subscription.expiration"
        static let lastValidationDate = "com.pdfgenius.validation.date"
    }

    // MARK: - Computed Properties

    var isPro: Bool {
        subscriptionTier == .pro
    }

    var isLifetime: Bool {
        store.isLifetime
    }

    var subscriptionExpirationDate: Date? {
        store.subscriptionExpirationDate
    }

    // MARK: - Initialization

    private init() {
        loadPersistedState()
    }

    // MARK: - Validate Subscription

    func validateSubscriptionState() async {
        await store.refreshSubscriptionStatus()

        if store.isLifetime || store.isPremium {
            subscriptionTier = .pro
        } else {
            subscriptionTier = .free
        }

        persistState()
    }

    /// Convenience alias used by PDFAppState
    func refreshCustomerInfo() async {
        await validateSubscriptionState()
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        await store.restore()
        await validateSubscriptionState()
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        let defaults = UserDefaults.standard

        if let tierRaw = defaults.string(forKey: UserDefaultsKey.subscriptionTier),
           let tier = SubscriptionTier(rawValue: tierRaw) {
            subscriptionTier = tier
        }

        if let expirationInterval = defaults.object(forKey: UserDefaultsKey.subscriptionExpiration) as? TimeInterval {
            let expirationDate = Date(timeIntervalSince1970: expirationInterval)
            if expirationDate <= Date() {
                // Subscription expired
                subscriptionTier = .free
            }
        }
    }

    private func persistState() {
        let defaults = UserDefaults.standard

        defaults.set(subscriptionTier.rawValue, forKey: UserDefaultsKey.subscriptionTier)

        if let expirationDate = subscriptionExpirationDate {
            defaults.set(expirationDate.timeIntervalSince1970, forKey: UserDefaultsKey.subscriptionExpiration)
        } else {
            defaults.removeObject(forKey: UserDefaultsKey.subscriptionExpiration)
        }

        defaults.set(Date().timeIntervalSince1970, forKey: UserDefaultsKey.lastValidationDate)
    }
}
