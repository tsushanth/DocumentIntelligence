import SwiftUI
import StoreKit

/// Paywall view for subscription upgrade
public struct PaywallView: View {

    @StateObject private var storeKit = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss

    private let appName: String
    private let features: [Feature]
    private let productID: String

    public init(appName: String, features: [Feature], productID: String) {
        self.appName = appName
        self.features = features
        self.productID = productID
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)

                        Text("Upgrade to Pro")
                            .font(.title.bold())

                        Text("Unlock all features of \(appName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)

                    // Features list
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features.filter(\.isPro), id: \.self) { feature in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }

                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Products
                    if let product = storeKit.products.first(where: { $0.id == productID }) {
                        VStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    await purchaseProduct(product)
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Subscribe Now")
                                            .font(.headline)

                                        Text("\(product.displayPrice)/month")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)

                            Button("Restore Purchases") {
                                Task {
                                    await restorePurchases()
                                }
                            }
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        }
                    }

                    // Terms
                    Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func purchaseProduct(_ product: Product) async {
        do {
            _ = try await storeKit.purchase(product)
            dismiss()
        } catch {
            print("Purchase failed: \(error)")
        }
    }

    private func restorePurchases() async {
        await storeKit.restore()
        if storeKit.hasActiveSubscription {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(
        appName: "DocuScan AI",
        features: [.ocr, .aiSummary, .autoTitle, .removeWatermark, .cloudSync],
        productID: StoreKitManager.ProductID.docuScanPro
    )
}
