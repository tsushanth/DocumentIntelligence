import SwiftUI
import PaywallKit

/// PaywallKit-powered paywall with StoreKit 2 purchases.
struct RemotePaywallView: View {
    @Environment(\.dismiss) private var dismiss
    var triggerSource: String = "unknown"
    @State private var didPurchaseOrRestore = false
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        PaywallKit.PaywallView(
            appId: "pdfgenius",
            appName: "PDFGenius Pro",
            features: [
                PaywallFeature(icon: "\u{270D}\u{FE0F}", title: "Signatures", description: "Sign documents digitally"),
                PaywallFeature(icon: "\u{1F916}", title: "AI Summaries", description: "Summarize any PDF"),
                PaywallFeature(icon: "\u{1F4DD}", title: "Annotations", description: "Draw and markup"),
                PaywallFeature(icon: "\u{1F504}", title: "Convert Files", description: "PDF to Word and more"),
                PaywallFeature(icon: "\u{1F4C1}", title: "Unlimited Documents", description: "No file limits")
            ],
            products: store.paywallProducts,
            theme: PaywallTheme(accent: Color(red: 0.9, green: 0.2, blue: 0.2), accent2: Color(red: 1.0, green: 0.5, blue: 0.0)),
            showWinback: true,
            onPurchase: { productId in
                let result = await store.purchase(productId: productId)
                if case .purchased = result {
                    didPurchaseOrRestore = true
                    await SubscriptionManager.shared.validateSubscriptionState()
                    await MainActor.run { dismiss() }
                    return true
                }
                return false
            },
            onRestore: {
                await store.restore()
                await SubscriptionManager.shared.validateSubscriptionState()
                if SubscriptionManager.shared.isPro {
                    didPurchaseOrRestore = true
                    await MainActor.run { dismiss() }
                }
            },
            onDismiss: {
                if !didPurchaseOrRestore {
                    PaywallCoordinator.shared.trackDismiss()
                }
                dismiss()
            }
        )
        .task {
            if store.paywallProducts.isEmpty {
                await store.loadProducts()
            }
        }
    }
}
