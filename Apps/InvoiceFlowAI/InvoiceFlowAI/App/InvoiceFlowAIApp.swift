import SwiftUI

@main
struct InvoiceFlowAIApp: App {

    @StateObject private var appState = InvoiceAppState()

    init() {
        // Initialize Facebook SDK for Meta Ads attribution
        FacebookSDKManager.shared.initialize()

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
