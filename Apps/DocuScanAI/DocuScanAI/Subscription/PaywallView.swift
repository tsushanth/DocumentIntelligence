import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    let feature: ProFeature?

    init(feature: ProFeature? = nil) {
        self.feature = feature
    }

    var body: some View {
        RevenueCatUI.PaywallView()
            .onPurchaseCompleted { _ in dismiss() }
            .onRestoreCompleted { _ in dismiss() }
    }
}

// MARK: - Paywall Modifier

struct PaywallModifier: ViewModifier {
    @ObservedObject private var gate = FeatureGate.shared

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $gate.showingPaywall) {
                PaywallView(feature: gate.paywallFeature)
            }
    }
}

extension View {
    func withPaywall() -> some View {
        modifier(PaywallModifier())
    }
}

#Preview {
    PaywallView(feature: .aiSummary)
}
