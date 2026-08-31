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
            appId: "invoiceflow",
            appName: "InvoiceFlow Pro",
            features: [
                PaywallFeature(icon: "📃", title: "Unlimited Invoices", description: "Create as many invoices as you need"),
                PaywallFeature(icon: "🎨", title: "Custom Branding", description: "Add your logo and brand colors"),
                PaywallFeature(icon: "👥", title: "Client Management", description: "Organize all your clients in one place"),
                PaywallFeature(icon: "📤", title: "PDF Export", description: "Send polished PDFs to your clients"),
            ],
            products: store.paywallProducts,
            theme: PaywallTheme(accent: Color(red: 0.1, green: 0.6, blue: 0.3), accent2: Color(red: 0.0, green: 0.45, blue: 0.2)),
            showWinback: true,
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
