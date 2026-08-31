import Foundation
import StoreKit

/// Manages in-app purchases and subscriptions using StoreKit 2
@MainActor
public final class StoreKitManager: ObservableObject {

    public static let shared = StoreKitManager()

    @Published public private(set) var subscriptionTier: SubscriptionTier = .free
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []

    private var updateListenerTask: Task<Void, Error>?

    // Product IDs - configure these in App Store Connect
    public enum ProductID {
        public static let docuScanPro = "com.documentintelligence.docuscan.pro.monthly"
        public static let pdfGeniusPro = "com.documentintelligence.pdfgenius.pro.monthly"
        public static let invoiceFlowPro = "com.documentintelligence.invoiceflow.pro.monthly"

        public static var all: [String] {
            [docuScanPro, pdfGeniusPro, invoiceFlowPro]
        }
    }

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load available products from the App Store
    public func loadProducts() async {
        do {
            let loadedProducts = try await Product.products(for: ProductID.all)
            products = loadedProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    /// Purchase a subscription
    public func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)

            // Update subscription status
            await updateSubscriptionStatus()

            // Finish the transaction
            await transaction.finish()

            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    /// Restore purchases
    public func restore() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Subscription Status

    /// Update the current subscription status
    public func updateSubscriptionStatus() async {
        var highestTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if subscription is active
                if transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)

                    // Determine tier based on product ID
                    if ProductID.all.contains(transaction.productID) {
                        highestTier = .pro
                    }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        subscriptionTier = highestTier
    }

    /// Check if user has an active subscription
    public var hasActiveSubscription: Bool {
        subscriptionTier == .pro
    }

    /// Check if a specific feature is available
    public func hasAccess(to feature: Feature) -> Bool {
        subscriptionTier.hasFeature(feature)
    }

    // MARK: - Transaction Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Updates

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    // MARK: - Subscription Info

    /// Get subscription status information
    public func getSubscriptionStatus(for productID: String) async -> Product.SubscriptionInfo.Status? {
        guard let product = products.first(where: { $0.id == productID }),
              let subscription = product.subscription else {
            return nil
        }

        guard let statuses = try? await subscription.status else {
            return nil
        }

        return statuses.first
    }

    /// Check if subscription will renew
    public func willRenew(productID: String) async -> Bool {
        guard let status = await getSubscriptionStatus(for: productID) else {
            return false
        }

        switch status.state {
        case .subscribed:
            return true
        default:
            return false
        }
    }
}

// MARK: - StoreKit Errors

public enum StoreKitError: LocalizedError {
    case failedVerification
    case purchaseFailed
    case productNotFound

    public var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase failed"
        case .productNotFound:
            return "Product not found"
        }
    }
}
