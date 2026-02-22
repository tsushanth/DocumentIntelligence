import RevenueCat
import SwiftUI

// MARK: - Entitlement IDs

enum EntitlementID: String {
    case pro = "pro"
}

// MARK: - Product IDs

enum ProductID: String, CaseIterable {
    case proMonthly = "docuscan_pro_monthly"
    case proAnnual = "docuscan_pro_annual"
    case proLifetime = "docuscan_pro_lifetime"

    var isSubscription: Bool {
        switch self {
        case .proMonthly, .proAnnual:
            return true
        case .proLifetime:
            return false
        }
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

// MARK: - Subscription Manager

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    override init() {
        super.init()
        configureRevenueCat()
    }

    // RevenueCat API Key
    private static let apiKey = "appl_GLZeYTvGYnnLQktoQgmqDInOsNW"

    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var subscriptionTier: SubscriptionTier = .free
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // Current offering packages
    var currentOffering: Offering? {
        offerings?.current
    }

    var monthlyPackage: Package? {
        currentOffering?.package(identifier: "$rc_monthly")
    }

    var annualPackage: Package? {
        currentOffering?.package(identifier: "$rc_annual")
    }

    var lifetimePackage: Package? {
        currentOffering?.package(identifier: "$rc_lifetime")
    }

    // MARK: - Configuration

    private func configureRevenueCat() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: Self.apiKey)

        // Enable automatic collection of Apple Search Ads attribution
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()

        // Listen for customer info updates
        Purchases.shared.delegate = self

        // Initial fetch
        Task {
            await loadOfferings()
            await refreshCustomerInfo()
        }
    }

    // MARK: - Load Offerings

    func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            #if DEBUG
            print("Failed to load offerings: \(error)")
            #endif
            errorMessage = "Failed to load products. Please try again."
        }
    }

    // MARK: - Refresh Customer Info

    func refreshCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionTier()
        } catch {
            #if DEBUG
            print("Failed to fetch customer info: \(error)")
            #endif
        }
    }

    // MARK: - Purchasing

    func purchase(_ package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)

            if !result.userCancelled {
                customerInfo = result.customerInfo
                updateSubscriptionTier()
                return true
            }
            return false
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionTier()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Update Subscription Tier

    private func updateSubscriptionTier() {
        guard let info = customerInfo else {
            subscriptionTier = .free
            return
        }

        #if DEBUG
        print("RevenueCat: Checking entitlements...")
        print("RevenueCat: All entitlements: \(info.entitlements.all.keys)")
        print("RevenueCat: Active entitlements: \(info.entitlements.active.keys)")
        #endif

        // Check for "pro" entitlement specifically
        if info.entitlements[EntitlementID.pro.rawValue]?.isActive == true {
            subscriptionTier = .pro
            #if DEBUG
            print("RevenueCat: Found active 'pro' entitlement")
            #endif
        }
        // Fallback: check if ANY entitlement is active (in case of naming mismatch)
        else if !info.entitlements.active.isEmpty {
            subscriptionTier = .pro
            #if DEBUG
            print("RevenueCat: Found other active entitlement, granting pro")
            #endif
        } else {
            subscriptionTier = .free
            #if DEBUG
            print("RevenueCat: No active entitlements, tier = free")
            #endif
        }
    }

    // MARK: - Helper Properties

    var isPro: Bool {
        subscriptionTier == .pro
    }

    var hasActiveSubscription: Bool {
        customerInfo?.entitlements.active.isEmpty == false
    }

    // Calculate savings for annual plan
    var annualSavingsPercent: Int {
        guard let monthly = monthlyPackage?.storeProduct.price,
              let annual = annualPackage?.storeProduct.price else { return 0 }

        let monthlyAnnualized = monthly * 12
        let savings = (monthlyAnnualized - annual) / monthlyAnnualized * 100
        return Int(truncating: savings as NSNumber)
    }

    // MARK: - User Identification (for attribution)

    func setUserID(_ userID: String) {
        Task {
            do {
                let (customerInfo, _) = try await Purchases.shared.logIn(userID)
                self.customerInfo = customerInfo
                updateSubscriptionTier()
            } catch {
                #if DEBUG
                print("Failed to login user: \(error)")
                #endif
            }
        }
    }

    func logout() {
        Task {
            do {
                customerInfo = try await Purchases.shared.logOut()
                updateSubscriptionTier()
            } catch {
                #if DEBUG
                print("Failed to logout: \(error)")
                #endif
            }
        }
    }

    // MARK: - Attribution

    func setSearchAdsAttribution(_ data: [String: Any]) {
        Purchases.shared.attribution.setAttributes(data.compactMapValues { "\($0)" })
    }

    func setCampaign(_ campaign: String) {
        Purchases.shared.attribution.setCampaign(campaign)
    }

    func setAdGroup(_ adGroup: String) {
        Purchases.shared.attribution.setAdGroup(adGroup)
    }

    func setCreative(_ creative: String) {
        Purchases.shared.attribution.setCreative(creative)
    }

    func setKeyword(_ keyword: String) {
        Purchases.shared.attribution.setKeyword(keyword)
    }
}

// MARK: - RevenueCat Delegate

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        #if DEBUG
        print("RevenueCat: Delegate received updated customer info")
        #endif
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.updateSubscriptionTier()
        }
    }
}

// MARK: - Price Formatting Extension

extension Package {
    var localizedPriceString: String {
        storeProduct.localizedPriceString
    }

    var pricePerMonth: String {
        let price = storeProduct.price
        let period = storeProduct.subscriptionPeriod

        guard let period = period else {
            return localizedPriceString
        }

        let monthlyPrice: Decimal
        switch period.unit {
        case .month:
            monthlyPrice = price / Decimal(period.value)
        case .year:
            monthlyPrice = price / Decimal(period.value * 12)
        case .week:
            monthlyPrice = price * Decimal(52 / 12) / Decimal(period.value)
        case .day:
            monthlyPrice = price * Decimal(365 / 12) / Decimal(period.value)
        @unknown default:
            monthlyPrice = price
        }

        let formatter = storeProduct.priceFormatter ?? NumberFormatter()
        formatter.numberStyle = .currency

        return formatter.string(from: monthlyPrice as NSNumber) ?? localizedPriceString
    }
}
