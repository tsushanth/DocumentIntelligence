import SwiftUI
import TikTokBusinessSDK
import PaywallKit

@main
struct PDFGeniusApp: App {

    @StateObject private var appState = PDFAppState()
    @StateObject private var paywallCoordinator = PaywallCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasRequestedATT = false

    init() {
        // Initialize TikTok Events SDK
        TikTokHelper.shared.initialize()

        // Configure StoreKit 2 via PaywallKit (replaces RevenueCat)
        StoreManager.shared.configure(productIds: ProductID.allIDs)
    }

    var body: some Scene {
        WindowGroup {
            PDFContentView()
                .environmentObject(appState)
                .sheet(isPresented: $paywallCoordinator.showWinbackOffer) {
                    WinbackOfferView()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await appState.checkSubscription() }
                paywallCoordinator.checkWinbackEligibility()
                if !hasRequestedATT {
                    hasRequestedATT = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        TikTokHelper.shared.requestTrackingPermission()
                    }
                }
            }
        }
    }
}

class PDFAppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var showPaywall: Bool = false

    private var subscriptionManager = SubscriptionManager.shared

    init() {
        Task {
            await checkSubscription()
        }
    }

    @MainActor
    func checkSubscription() async {
        await subscriptionManager.validateSubscriptionState()
        isProUser = subscriptionManager.isPro
    }
}
