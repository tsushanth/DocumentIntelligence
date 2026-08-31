import SwiftUI
import RevenueCat

@main
struct InvoiceFlowAIApp: App {

    @StateObject private var appState = InvoiceAppState()

    init() {
        configureRevenueCat()

        // Fetch Apple Search Ads attribution on app launch
        Task {
            await SearchAdsAttribution.shared.fetchAttribution()
        }
    }

    var body: some Scene {
        WindowGroup {
            InvoiceContentView()
                .environmentObject(appState)
        }
    }
}

class InvoiceAppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var showPaywall: Bool = false
    @Published var invoicesThisMonth: Int = 0
    
    let freeInvoiceLimit = 3
    
    var canCreateInvoice: Bool {
        isProUser || invoicesThisMonth < freeInvoiceLimit
    }
    
    init() {
        Task {
            await checkSubscription()
        }
    }
    
    @MainActor
    func checkSubscription() async {
        // Will integrate with StoreKitManager
    }
}

/// Configures RevenueCat for subscription tracking and cross-platform LTV attribution.
/// Purchases continue to be made and finished via StoreKitManager, so RevenueCat is
/// configured in observer mode: it tracks transactions rather than completing them.
private func configureRevenueCat() {
    #if DEBUG
    Purchases.logLevel = .debug
    #endif

    let configuration = Configuration.Builder(withAPIKey: "appl_TvXnRqLdMbZkYcWjPuAeSgFhKo")
        .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)
        .build()
    Purchases.configure(with: configuration)

    // Enable automatic collection of Apple Search Ads attribution
    Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
}
