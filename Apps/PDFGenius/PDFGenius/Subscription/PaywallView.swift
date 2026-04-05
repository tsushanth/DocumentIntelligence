import SwiftUI
import PaywallKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    let feature: ProFeature?

    init(feature: ProFeature? = nil) {
        self.feature = feature
    }

    var body: some View {
        // Delegate to RemotePaywallView which handles everything via StoreManager
        RemotePaywallView(triggerSource: feature?.rawValue ?? "generic")
    }
}

// MARK: - Paywall Modifier

struct PaywallModifier: ViewModifier {
    @ObservedObject private var gate = FeatureGate.shared

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $gate.showingPaywall) {
                RemotePaywallView(triggerSource: gate.paywallFeature?.rawValue ?? "generic")
            }
    }
}

extension View {
    func withPaywall() -> some View {
        modifier(PaywallModifier())
    }
}

#Preview {
    PaywallView(feature: .signatures)
}
