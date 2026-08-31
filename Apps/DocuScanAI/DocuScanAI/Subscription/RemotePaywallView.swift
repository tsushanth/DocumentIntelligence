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
            appId: "docuscan",
            appName: "DocuScan AI Pro",
            features: [
                PaywallFeature(icon: "📄", title: "AI Document Scanning", description: "Intelligent scanning with auto-enhancement"),
                PaywallFeature(icon: "📋", title: "PDF Export", description: "Export any document as a polished PDF"),
                PaywallFeature(icon: "🔍", title: "OCR Text Extraction", description: "Extract text from scanned documents"),
                PaywallFeature(icon: "☁️", title: "Cloud Sync", description: "Access your documents anywhere"),
            ],
            products: store.paywallProducts,
            theme: PaywallTheme(accent: Color(red: 0.1, green: 0.45, blue: 0.85), accent2: Color(red: 0.0, green: 0.6, blue: 0.75)),
            showWinback: false,
            onPurchase: { productId in
                let result = await store.purchase(productId: productId)
                if case .purchased = result {
                    didPurchaseOrRestore = true
                    await MainActor.run { dismiss() }
                    return true
                }
                return false
            },
            onRestore: {
                await store.restore()
                if store.isPremium {
                    didPurchaseOrRestore = true
                    await MainActor.run { dismiss() }
                }
            },
            onDismiss: {
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
