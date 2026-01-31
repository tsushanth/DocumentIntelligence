import SwiftUI

/// Controls access to features based on subscription status
public struct FeatureGate<Content: View>: View {

    @StateObject private var storeKit = StoreKitManager.shared

    private let feature: Feature
    private let appName: String
    private let productID: String
    private let content: () -> Content

    @State private var showingPaywall = false

    public init(
        feature: Feature,
        appName: String,
        productID: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.feature = feature
        self.appName = appName
        self.productID = productID
        self.content = content
    }

    public var body: some View {
        Group {
            if storeKit.hasAccess(to: feature) {
                content()
            } else {
                Button(action: {
                    showingPaywall = true
                }) {
                    Label("Upgrade to Pro", systemImage: "lock.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
                .sheet(isPresented: $showingPaywall) {
                    PaywallView(
                        appName: appName,
                        features: SubscriptionTier.pro.features.map { $0 },
                        productID: productID
                    )
                }
            }
        }
    }
}

/// ViewModifier to lock features behind paywall
public struct FeatureLock: ViewModifier {

    @StateObject private var storeKit = StoreKitManager.shared

    private let feature: Feature
    private let appName: String
    private let productID: String

    @State private var showingPaywall = false

    public init(feature: Feature, appName: String, productID: String) {
        self.feature = feature
        self.appName = appName
        self.productID = productID
    }

    public func body(content: Content) -> some View {
        content
            .disabled(!storeKit.hasAccess(to: feature))
            .overlay(alignment: .topTrailing) {
                if !storeKit.hasAccess(to: feature) {
                    Button(action: {
                        showingPaywall = true
                    }) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .offset(x: -8, y: 8)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(
                    appName: appName,
                    features: SubscriptionTier.pro.features.map { $0 },
                    productID: productID
                )
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Lock a feature behind a paywall
    public func featureLocked(
        _ feature: Feature,
        appName: String,
        productID: String
    ) -> some View {
        modifier(FeatureLock(feature: feature, appName: appName, productID: productID))
    }

    /// Show upgrade prompt if feature is not available
    public func requiresProFeature(
        _ feature: Feature,
        appName: String,
        productID: String
    ) -> some View {
        FeatureGate(feature: feature, appName: appName, productID: productID) {
            self
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Text("Pro Feature Content")
            .featureLocked(.aiSummary, appName: "DocuScan AI", productID: StoreKitManager.ProductID.docuScanPro)
    }
}
